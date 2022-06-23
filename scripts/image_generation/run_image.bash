#!/bin/bash

now=$(date +"%T")
echo "===========> Running $1 at $now"
echo "===========> Navigating to ../../matlab/$1/"
cd ../../matlab/$1/

echo "=====> Generating images with matlab"
#matlab.exe -nodisplay -nosplash -nodesktop -r "run('Generate_64_by_64.m');exit;"

echo "=====> Converting image_test_64_by_64.txt"
python ../../scripts/image_generation/clean.py image_test_64_by_64.txt
mv image_test_64_by_64.txt_clean image_test_64_by_64_clean
python ../../scripts/image_generation/convert_unsigned_decimal_to_binary.py image_test_64_by_64_clean

echo "=====> Converting self_smoothed_image_test_64_by_64.txt"
python ../../scripts/image_generation/clean.py self_smoothed_image_test_64_by_64.txt
mv self_smoothed_image_test_64_by_64.txt_clean self_smoothed_image_test_64_by_64_clean
python ../../scripts/image_generation/convert_unsigned_decimal_to_binary.py self_smoothed_image_test_64_by_64_clean

echo "=====> Converting equalized_self_smoothed_image_test_64_by_64.txt"
python ../../scripts/image_generation/clean.py equalized_self_smoothed_image_test_64_by_64.txt
mv equalized_self_smoothed_image_test_64_by_64.txt_clean equalized_self_smoothed_image_test_64_by_64_clean
python ../../scripts/image_generation/convert_unsigned_decimal_to_binary.py equalized_self_smoothed_image_test_64_by_64_clean

echo "=====> Converting equalized_image_test_64_by_64.txt"
python ../../scripts/image_generation/clean.py equalized_image_test_64_by_64.txt
mv equalized_image_test_64_by_64.txt_clean equalized_image_test_64_by_64_clean
python ../../scripts/image_generation/convert_unsigned_decimal_to_binary.py equalized_image_test_64_by_64_clean

echo "=====> Converting self_smoothed_equalized_image_test_64_by_64.txt"
python ../../scripts/image_generation/clean.py self_smoothed_equalized_image_test_64_by_64.txt
mv self_smoothed_equalized_image_test_64_by_64.txt_clean self_smoothed_equalized_image_test_64_by_64_clean
python ../../scripts/image_generation/convert_unsigned_decimal_to_binary.py self_smoothed_equalized_image_test_64_by_64_clean

echo "=====> Navigating to ../../scripts/image_generation/"
cd ../../scripts/image_generation/
now=$(date +"%T")
echo "===========> Finished $1 at $now"