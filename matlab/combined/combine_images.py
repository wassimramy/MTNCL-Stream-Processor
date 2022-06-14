
import os
import math
import sys

writefile = open(sys.argv[1], "w")
with open("../lena/" + sys.argv[1]) as name_file, open("../cameraman/" +sys.argv[1]) as job_file:
    for name_line, job_line in zip(name_file, job_file):
        #print("{}{}".format(name_line.strip(), job_line))
	writefile.write("{}{}".format(name_line.strip(), job_line))

