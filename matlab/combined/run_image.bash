#!/bin/bash

python combine_images.py image_test_64_by_64_clean_binary
python combine_images.py self_smoothed_image_test_64_by_64_clean_binary
python combine_images.py equalized_self_smoothed_image_test_64_by_64_clean_binary
python combine_images.py equalized_image_test_64_by_64_clean_binary
python combine_images.py self_smoothed_equalized_image_test_64_by_64_clean_binary

