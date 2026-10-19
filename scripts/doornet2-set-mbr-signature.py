#!/usr/bin/env python3
"""Set a deterministic DoorNet2-specific MBR disk signature before image gzip.

The OpenWrt rockchip boot script obtains part 2's UUID dynamically from the
selected MMC device. Changing only the MBR signature at offset 440 avoids
identical PARTUUIDs between TF and an already-installed stock OpenWrt eMMC.
"""
import argparse
from pathlib import Path
import struct

parser=argparse.ArgumentParser()
parser.add_argument('image',type=Path)
parser.add_argument('--signature',default='0xD0021000')
args=parser.parse_args()
signature=int(args.signature,0)
if not 0 < signature <= 0xffffffff:
    parser.error('MBR signature must be a nonzero 32-bit value')
with args.image.open('r+b') as fp:
    hdr=bytearray(fp.read(512))
    if len(hdr)!=512 or hdr[510:512]!=b'\x55\xaa':
        raise SystemExit('REFUSE: expected a complete MBR image (not raw filesystem)')
    parts=[]
    for i in (0,1):
        entry=hdr[446+16*i:446+16*(i+1)]
        start,nsect=struct.unpack_from('<II',entry,8)
        if start==0 or nsect==0:
            raise SystemExit(f'REFUSE: missing MBR partition {i+1}')
        parts.append((start,nsect))
    if parts[0][0]+parts[0][1] > parts[1][0]:
        raise SystemExit('REFUSE: partition overlap')
    fp.seek(0,2)
    image_size=fp.tell()
    if (parts[1][0]+parts[1][1])*512 > image_size:
        raise SystemExit('REFUSE: MBR partitions exceed image size')
    prev=struct.unpack_from('<I',hdr,440)[0]
    if prev not in (0x5452574f,signature):
        raise SystemExit(f'REFUSE: unexpected old signature: 0x{prev:08x}')
    fp.seek(440)
    fp.write(struct.pack('<I',signature))
    fp.flush()
    fp.seek(440)
    if struct.unpack('<I',fp.read(4))[0] != signature:
        raise SystemExit('MBR write verification failed')
print(f'DoorNet2 MBR signature: 0x{signature:08x}; root PARTUUID: {signature:08x}-02')
