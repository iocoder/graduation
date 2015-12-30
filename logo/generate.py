#!/usr/bin/python2

# This python script converts university logo (PNG) into binary format
# to be embedded in BIOS. BIOS shall use the binary-coded data to draw
# the logo in VGA text mode.

import os
import sys
import struct
from PIL import Image

# check command-line arguments
if (len(sys.argv) != 4):
    sys.stderr.write("Usage: " + sys.argv[0] + " pngfile txtfile binfile\n")
    exit(-1)

# open logo.png for read
pngfile = Image.open(sys.argv[1])

# open logo.txt for write
txtfile = open(sys.argv[2], "w")

# open logo.bin for write
binfile = open(sys.argv[3], "w")

# read image information and data from pngfile
pixels    = pngfile.load()
width     = pngfile.size[0]
height    = pngfile.size[1]
width_al  = ((width+8)/9)*9
height_al = (height+15)&~15

# print image information to stdout
print "Width:", width
print "Height:", height
print "Aligned width:", width_al
print "Aligned height:", height_al

# store image dimensions in the first 8 bytes of binfile:
binfile.write(struct.pack("I", width_al))
binfile.write(struct.pack("I", height_al))

# loop over pixels of the image
curbyte = 0
for y in range(0, height_al):
    for x in range(0, width_al):
        if x < width and y < height and pixels[x,y][0] < 5:
            # pixel is black
            txtfile.write('*')
            curbyte = (curbyte<<1)|1
        else:
            # pixel is white
            txtfile.write(' ')
            curbyte <<= 1
        if (x%9 == 8):
            # write to last 9 pixels to binary file
            binfile.write(chr((curbyte>>0)&0xFF))
            binfile.write(chr((curbyte>>8)&0xFF))
            curbyte = 0
    curbyte = 0
    txtfile.write('\n')

# close files
pngfile.close()
txtfile.close()
binfile.close()
