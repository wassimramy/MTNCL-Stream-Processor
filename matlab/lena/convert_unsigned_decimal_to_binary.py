
import os
import math
import sys


readfile = open(sys.argv[1])
writefile = open(sys.argv[1] + "_binary", "w")
scale = 8

for line in readfile:
	n = "{0:08b}".format(int(line)).zfill(8)
	writefile.write(n)
	writefile.write("\n")	
