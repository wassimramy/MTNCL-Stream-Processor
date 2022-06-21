
import sys

f1=open(sys.argv[1],"r+")
input=f1.read()
print(input)
input=input.replace(',','\n')
print(input)
f2=open(sys.argv[1]+"_clean","w+")
f2.write(input)
f1.close()
f2.close()