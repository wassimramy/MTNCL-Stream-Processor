import sys


#read input file
fin = open("image_test_64_by_64_clean_binary_one_line", "rt")
#read file contents to string
data = fin.read()
#replace all occurrences of the required string
data = data.replace('\n', '')
#close the input file
fin.close()
#open the input file in write mode
fin = open("image_test_64_by_64_clean_binary_one_line", "wt")
#overrite the input file with the resulting data
fin.write(data)
#close the file
fin.close()
