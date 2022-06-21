
import os
import math
import sys


readfile = open(sys.argv[1])
writefile = open(sys.argv[1] + "_binary", "w")
writefile_pixel_count = open(sys.argv[1] + "_binary_pixel_count", "w")
writefile_pixel_count_steps = open(sys.argv[1] + "_binary_pixel_count_steps", "w")
shade_count = [0] * 257
scale = 8

for line in readfile:
	n = "{0:08b}".format(int(line)).zfill(8)
	shade_count [int(line)-1] += 1;
	for index in range(0, 256):
		n_12 = "{0:08b}".format(shade_count[256-index]).zfill(12)
		writefile_pixel_count_steps.write(n_12)
	writefile_pixel_count_steps.write("\n")
	writefile.write(n)
	writefile.write("\n")

for index in range(0, 256):
	n_12 = "{0:08b}".format(shade_count[256-index]).zfill(12)
	writefile_pixel_count.write(n_12)
	writefile_pixel_count.write("\n")

