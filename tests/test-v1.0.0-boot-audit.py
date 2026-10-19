#!/usr/bin/env python3
"""Negative/positive fixture: tests V1 static verifier, does not test hardware."""
from pathlib import Path
import gzip
import hashlib
import struct
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]

def make_dt(nodes, payloads=None):
    names=sorted({k for _path,props in nodes for k in props})
    strings=bytearray()
    offsets={}
    for name in names:
        offsets[name]=len(strings)
        strings.extend(name.encode()+b'\0')
    s=bytearray()
    def pad():
        while len(s)%4:s.append(0)
    def emit(path,subtree):
        s.extend(struct.pack('>I',1));s.extend(path.encode()+b'\0');pad()
        for key,val in subtree.items():
            s.extend(struct.pack('>III',3,len(val),offsets[key]));s.extend(val);pad()
    # each is a full absolute path, expanded into a simple preorder tree
    emitted=[]
    for path,props in nodes:
        components=path.strip('/').split('/') if path!='/' else []
        stack=['']+components
        shared=0
        while shared<len(emitted) and shared<len(stack) and emitted[shared]==stack[shared]: shared+=1
        for _ in range(len(emitted)-shared):s.extend(struct.pack('>I',2))
        for comp in stack[shared:]:
            s.extend(struct.pack('>I',1));s.extend(comp.encode()+b'\0');pad()
        emitted=stack
        for key,val in props.items():
            s.extend(struct.pack('>III',3,len(val),offsets[key]));s.extend(val);pad()
    for _ in emitted:s.extend(struct.pack('>I',2))
    s.extend(struct.pack('>I',9))
    total=40+len(s)+len(strings)
    return struct.pack('>10I',0xd00dfeed,total,40,40+len(s),0,17,16,0,len(strings),len(s))+s+strings

uboot=b'ABCDEFG'+b'boot_targets=mmc0 mmc1 nvme scsi usb pxe dhcp spi\0'+b'1234'
dtb=make_dt([('/',{}),('/aliases',{'mmc0':b'/mmc@fe320000\0','mmc1':b'/mmc@fe330000\0'})])
# FIT data-offset measured after aligned FDT header; data chunks are inline.
fit=make_dt([
    ('/',{}),('/images',{}),
    ('/images/u-boot',{'data-offset':struct.pack('>I',0),'data-size':struct.pack('>I',len(uboot))}),
    ('/images/u-boot/hash',{'algo':b'sha256\0','value':hashlib.sha256(uboot).digest()}),
    ('/images/fdt-1',{'data-offset':struct.pack('>I',len(uboot)),'data-size':struct.pack('>I',len(dtb))}),
    ('/images/fdt-1/hash',{'algo':b'sha256\0','value':hashlib.sha256(dtb).digest()}),
])
fit+=b'\0'*((-len(fit))%4)
fit+=uboot+dtb
image=bytearray(80*1024*1024)
struct.pack_into('<I',image,440,0xD0021000)
image[510:512]=b'\x55\xaa'
for i,(lba,num) in enumerate([(65536,32768),(131072,32768)]):
    struct.pack_into('<II',image,446+16*i+8,lba,num)
image[64*512:64*512+4]=b'IDB!'
boot=32*1024*1024
image[boot+1024+56:boot+1024+58]=b'\x53\xef'
marker=b'part uuid mmc ${devnum}:2 uuid root=PARTUUID=${uuid}'
image[boot+3000:boot+3000+len(marker)]=marker
image[64*1024*1024:64*1024*1024+4]=b'hsqs'
image[8*1024*1024:8*1024*1024+len(fit)]=fit
with tempfile.TemporaryDirectory(prefix='doornet2-v1-static-') as d:
    gz=Path(d)/'synthetic.img.gz'
    with gzip.open(gz,'wb',compresslevel=1) as f:f.write(image)
    command=[sys.executable,str(root/'scripts/verify-doornet2-boot.py'),str(gz)]
    subprocess.run(command,check=True)
    # A duplicate legacy OpenWrt signature must fail.
    struct.pack_into('<I',image,440,0x5452574f)
    with gzip.open(gz,'wb',compresslevel=1) as f:f.write(image)
    result=subprocess.run(command,capture_output=True,text=True)
    assert result.returncode!=0 and 'disk signature' in result.stderr,repr(result)
print('PASS: boot-chain validator accepts correct fixture, refuses duplicate-root-ID fixture')
