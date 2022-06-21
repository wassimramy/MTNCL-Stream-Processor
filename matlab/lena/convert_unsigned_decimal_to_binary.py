
import os
import math
import sys


readfile = open(sys.argv[1])
writefile = open(sys.argv[1] + "_binary", "w")
writefile_pixel_count = open(sys.argv[1] + "_binary_pixel_count", "w")
shade_count = []
scale = 8

for line in readfile:
	n = "{0:08b}".format(int(line)).zfill(8)
	shade_count [int(line)] += 1; 
	writefile_pixel_count.write(shade_count)
	writefile_pixel_count.write("\n")
	writefile.write(n)
	writefile.write("\n")
