image_test = imread('lena.tiff');
image_test_256_by_256 = imresize(image_test, 0.5);
image_test_128_by_128 = imresize(image_test_256_by_256, 0.5);
image_test_64_by_64 = imresize(image_test_128_by_128, 0.5);

box_filter = (1/16) *[1 2 1; 2 4 2; 1 2 1];
smoothed_image_test_64_by_64 =              imfilter (image_test_64_by_64, box_filter, 'full', 0);

   
for i = 1:64
    for j = 1:4
        input_image(i+1,j+1) = image_test_64_by_64(i,j)
    end
end

for i = 1:66
        input_image(66,i) = 0
        input_image(i,66) = 0
end

for i = 2:65
    for j = 2:65
        self_smoothed_image_test_64_by_64(i-1,j-1) = round(( ...
            1*input_image(i-1,j-1)+2*input_image(i-1,j)+1*input_image(i-1,j+1)+ ...
            2*input_image(i,j-1)+4*input_image(i,j)+2*input_image(i,j+1) +...
            1*input_image(i+1,j-1)+2*input_image(i+1,j)+1*input_image(i+1,j+1) ...
            )/16);
    end
end 

writematrix(image_test_64_by_64, 'image_test_64_by_64');
writematrix(input_image, 'image_test_65_by_65');
writematrix(smoothed_image_test_64_by_64, 'smoothed_image_test_64_by_64');
writematrix(self_smoothed_image_test_64_by_64, 'self_smoothed_image_test_64_by_64');

%fileID = fopen('image_test_64_by_64.txt');
%fwrite(fileID,image_test_64_by_64, 'uint');
%fwrite(fileID ,image_test_64_by_64, 'double','ieee-be');
%fclose (fileID);
% box_filter = (1/16) *[1 2 1; 2 4 2; 1 2 1];
% smoothed_image_test_64_by_64 =              imfilter (image_test_64_by_64, box_filter);
% equalized_image_test_64_by_64 =             histeq (image_test_64_by_64);
% smoothed_equalized_image_test_64_by_64 =    imfilter (equalized_image_test_64_by_64, box_filter);
% equalized_smoothed_image_test_64_by_64 =    histeq (smoothed_image_test_64_by_64);
% 
% imwrite( image_test_64_by_64 ,                          '03_0 64 by 64.jpg');
% imwrite( smoothed_image_test_64_by_64 ,                 '03_1 Smoothed 64 by 64.jpg');
% imwrite( equalized_image_test_64_by_64 ,                '03_2 Equalized 64 by 64.jpg');
% imwrite( smoothed_equalized_image_test_64_by_64 ,       '03_3 Smoothed Equalized 64 by 64.jpg');
% imwrite( equalized_smoothed_image_test_64_by_64 ,       '03_4 Equalized Smoothed 64 by 64.jpg');

