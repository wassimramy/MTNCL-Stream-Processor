#!/bin/bash

pwd
python clean.py /mnt/c/Users/wrkhalil/OneDrive\ -\ University\ of\ Arkansas/Graduate/Research/Dissertation/VHDL_Cores/19_Global_RTL/matlab/cameraman/image_test_64_by_64.txt
python convert_unsigned_decimal_to_binary.py "image_test_64_by_64.txt_clean"
mv image_test_64_by_64.txt_clean_binary image_test_64_by_64_clean_binary