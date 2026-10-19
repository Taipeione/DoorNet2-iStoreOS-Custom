#!/usr/bin/env python3
"""Static Rockchip boot-chain audit for whole-disk OpenWrt sysupgrade images.

This gate does not prove the RK3399 BootROM selected TF or DDR3L trained.
It checks the supplied image's independent boot structures and avoids the
old V0.1 false positive where a valid gzip image didn't boot the board.
"""
import argparse
from pathlib import Path
import hashlib
import struct
import zlib

p=argparse.ArgumentParser()
p.add_argument('path',type=Path)
p.add_argument('--expected-signature',type=lambda s:int(s,0),default=0xD0021000)
a=p.parse_args()
raw=a.path.read_bytes()
obj=zlib.decompressobj(31)
image=obj.decompress(raw)+obj.flush()
if not obj.eof:
    raise SystemExit('FAIL: missing/invalid gzip stream')
if image[:512].count(b'\0')==512:
    raise SystemExit('FAIL: empty MBR')
if image[510:512]!=b'\x55\xaa':
    raise SystemExit('FAIL: missing MBR 55aa signature')
sig=struct.unpack_from('<I',image,440)[0]
if sig!=a.expected_signature:
    raise SystemExit(f'FAIL: image disk signature {sig:08x} differs from expected {a.expected_signature:08x}')
partitions=[]
for i in (0,1):
    entry=446+16*i
    lba,blocks=struct.unpack_from('<II',image,entry+8)
    if not lba or not blocks or (lba+blocks)*512>len(image):
        raise SystemExit(f'FAIL: partition {i+1} invalid')
    partitions.append((lba,blocks))
if partitions[0][0]*512!=32*1024*1024:
    raise SystemExit(f'FAIL: unexpected boot partition offset {partitions[0][0]*512}')
if partitions[1][0]*512!=64*1024*1024:
    raise SystemExit(f'FAIL: unexpected root partition offset {partitions[1][0]*512}')
if partitions[0][0]+partitions[0][1]>partitions[1][0]:
    raise SystemExit('FAIL: overlapping partitions')
boot_start=partitions[0][0]*512
boot_end=(partitions[0][0]+partitions[0][1])*512
boot=image[boot_start:boot_end]
if boot[1024+56:1024+58]!=b'\x53\xef':
    raise SystemExit('FAIL: OpenWrt boot partition is not ext4')
# The stock mmc.bootscript gets the chosen devnum's partition 2 UUID at boot.
# A static or stale hardcoded root=UUID would silently boot the wrong eMMC.
if b'part uuid mmc ${devnum}:2 uuid' not in boot or b'root=PARTUUID=${uuid}' not in boot:
    raise SystemExit('FAIL: boot.scr is missing dynamic root PARTUUID commands')
if not any(b in image[partitions[1][0]*512:partitions[1][0]*512+4] for b in (b'hsqs',b'\x53\xef')):
    # ext4 roots have superblock signature at offset 1080, checked separately
    off=partitions[1][0]*512
    if image[off+1024+56:off+1024+58]!=b'\x53\xef':
        raise SystemExit('FAIL: unknown rootfs signature')
# SPL/Rockchip loader starts at 32KiB, U-Boot FIT at 8MiB.
if image[64*512:64*512+1024]==b'\0'*1024:
    raise SystemExit('FAIL: RK3399 idbloader/SPL region empty')
fit_offset=8*1024*1024
if image[fit_offset:fit_offset+4]!=b'\xd0\x0d\xfe\xed':
    raise SystemExit('FAIL: U-Boot FIT magic absent at expected 8MiB')
head=struct.unpack_from('>10I',image,fit_offset)
size,off_struct,off_strings,off_mem,version,last,bootcpu,size_strings,size_struct=head[1:]
if not 0<size<1024*1024 or off_struct>=size or off_strings>=size or not size_struct:
    raise SystemExit('FAIL: corrupt Rockchip FIT header')
# U-Boot env is stored within a FIT payload, typically /images/u-boot.
def fdt_props(data,pos):
    v=struct.unpack_from('>10I',data,pos)
    total,so,st,ml,ver,last,boot,ss,sz=v[1:]
    if data[pos:pos+4]!=b'\xd0\x0d\xfe\xed' or total<=0 or total>1024*1024:
        raise ValueError('bad FDT')
    idx=pos+so
    stop=idx+sz
    nodes=[]
    props={}
    while idx<stop:
        token=struct.unpack_from('>I',data,idx)[0]
        idx+=4
        if token==1:
            end=data.index(0,idx,stop)
            nodes.append(data[idx:end].decode())
            idx=(end+4)&~3
        elif token==2:
            if not nodes: raise ValueError('bad END_NODE')
            nodes.pop()
        elif token==3:
            length,name_offset=struct.unpack_from('>II',data,idx)
            idx+=8
            nameptr=pos+st+name_offset
            nameend=data.index(0,nameptr,pos+total)
            name=data[nameptr:nameend].decode()
            value=data[idx:idx+length]
            if idx+length>stop: raise ValueError('bad prop length')
            key=('/'+'/'.join(n for n in nodes if n),name)
            props[key]=value
            idx=(idx+length+3)&~3
        elif token==4: pass
        elif token==9: break
        else: raise ValueError(f'bad FDT token {token}')
    return total,props
try:
    total,props=fdt_props(image,fit_offset)
    loc='/images/u-boot'
    offset=struct.unpack('>I',props[(loc,'data-offset')])[0]
    length=struct.unpack('>I',props[(loc,'data-size')])[0]
    begin=fit_offset+((total+3)&~3)+offset
    end=begin+length
    if not(fit_offset<begin<end<16*1024*1024):raise ValueError('bad u-boot span')
    code=image[begin:end]
    hashval=props.get((loc+'/hash','value'))
    if hashval and hashval!=hashlib.sha256(code).digest():
        raise ValueError('invalid U-Boot payload SHA256')
except (ValueError,KeyError,struct.error) as e:
    raise SystemExit(f'FAIL: cannot verify FIT U-Boot payload: {e}')
# Inspect the actual FIT DTB, not just the source DTS. The selected boot
# target order is meaningful only if the compiled aliases map TF to mmc0.
try:
    dtpath='/images/fdt-1'
    dtoffset=struct.unpack('>I',props[(dtpath,'data-offset')])[0]
    dtlen=struct.unpack('>I',props[(dtpath,'data-size')])[0]
    start=fit_offset+((total+3)&~3)+dtoffset
    finish=start+dtlen
    if not (fit_offset<start<finish<16*1024*1024):
        raise ValueError('out-of-bounds fdt-1 payload')
    dtb=image[start:finish]
    dt_hash=props.get((dtpath+'/hash','value'))
    if dt_hash and dt_hash!=hashlib.sha256(dtb).digest():
        raise ValueError('bad fdt-1 hash')
    _,dprops=fdt_props(dtb,0)
    if dprops[('/aliases','mmc0')]!=b'/mmc@fe320000\0':
        raise ValueError('mmc0 is not SD/TF controller fe320000')
    if dprops[('/aliases','mmc1')]!=b'/mmc@fe330000\0':
        raise ValueError('mmc1 is not eMMC controller fe330000')
except (ValueError,KeyError,struct.error) as e:
    raise SystemExit(f'FAIL: wrong U-Boot DTB MMC aliases: {e}')
if b'boot_targets=mmc0 mmc1 nvme scsi usb pxe dhcp spi\0' not in code:
    raise SystemExit('FAIL: embedded U-Boot boot_targets is not TF-first mmc0 mmc1')
if b'boot_targets=mmc1 mmc0 nvme scsi usb pxe dhcp spi\0' in code:
    raise SystemExit('FAIL: embedded U-Boot still contains eMMC-first boot targets')
print(f'PASS: MBR root PARTUUID={sig:08x}-02, OpenWrt boot script dynamic, FIT 8MiB, TF-first U-Boot env and MMC aliases')
print('NOT TESTED: ROM boot order, TF DDR training, physical Ethernet and eMMC fallback')
