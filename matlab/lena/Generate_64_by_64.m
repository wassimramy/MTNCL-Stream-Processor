size = 64;
numberOfShades = 256;
image_test = imread('lena.tiff');

%Generate smaller size images
image_test_256_by_256 = imresize(image_test, 0.5);
image_test_128_by_128 = imresize(image_test_256_by_256, 0.5);
image_test_32_by_32 = imresize(image_test_128_by_128, 0.5);
%image_test_32_by_32 = imresize(image_test_64_by_64, 0.5);

%Generate an imfilter smoothed picture
box_filter = (1/16) *[1 2 1; 2 4 2; 1 2 1];
smoothed_image_test_32_by_32 =              imfilter (image_test_32_by_32, box_filter);

%Generate a self smoothed image
%Put the image in a bigger image(matrix) to add the extra "0" pixels   
for i = 1:size
    for j = 1:size
        input_image(i+1,j+1) = double(image_test_32_by_32(i,j));
    end
end

%Set the dummy pixels to 0
for i = 1:size+2
    input_image(i,1) = 0;
    input_image(i,size+2) = 0;
end

%Average the box filter and output the self smoothed picture
double temp
for i = 2:size+1
    for j = 2:size+1
           temp = double(1*input_image(i-1,j-1)+2*input_image(i-1,j)+1*input_image(i-1,j+1)+2*input_image(i,j-1)+4*input_image(i,j)+2*input_image(i,j+1)+ double(1*input_image(i+1,j-1))+double(2*input_image(i+1,j))+double(1*input_image(i+1,j+1)));
           self_smoothed_image_test_32_by_32(i-1,j-1) =  round(temp/16);
    end
end 


%Equalize the plain picture
sum = 0;

for x = 1:numberOfShades
    a(x) = 0;
    probability(x) = 0;
end

for x = 1:size
    for y = 1:size
        a(image_test_32_by_32(y,x)) = a(image_test_32_by_32(y,x)) +1;
    end 
end

for x = 1:numberOfShades
    probability(x) = a(x)/(size*size);
end

for x = 1:numberOfShades
    aEqualized(x) = 0;
    cumulative(x) = 0;
end
for x = 1:numberOfShades
    sum = sum + a(x);
    cumulative(x) = sum;
    probability(x) = cumulative(x) * numberOfShades;
    result(x) =  floor((probability(x)/(size*size)));
end

equalized_image_test_32_by_32=uint8(zeros(size,size));
for x=1:size
       for y=1:size
           equalized_image_test_32_by_32(x,y) = result(image_test_32_by_32(x,y));
       end
end

%Equalize the self smoothed picture
sum = 0;
for x = 1:numberOfShades
        a(x) = 0;
end
for x = 1:size
    for y = 1:size
        a(self_smoothed_image_test_32_by_32(y,x)) = a(self_smoothed_image_test_32_by_32(y,x)) +1;
    end 
end

for x = 1:numberOfShades
    probability(x) = a(x)/(size*size);
end

for x = 1:numberOfShades
    result(x) = 0;
    probability(x) = 0;
    aEqualized(x) = 0;
    cumulative(x) = 0;
end
for x = 1:numberOfShades
    sum = sum + a(x);
    cumulative(x) = sum;
    probability(x) = cumulative(x) * numberOfShades;
    result(x) =  floor((probability(x)/(size*size)));
end

equalized_self_smoothed_image_test_32_by_32=uint8(zeros(size,size));
for x=1:size
       for y=1:size
           equalized_self_smoothed_image_test_32_by_32(x,y) = result(self_smoothed_image_test_32_by_32(x,y));
       end
end

%Generate a self smoothed image from the equalized one
%Put the image in a bigger image(matrix) to add the extra "0" pixels   
for i = 1:size
    for j = 1:size
        input_image(i+1,j+1) = double(equalized_image_test_32_by_32(i,j));
    end
end

%Set the dummy pixels to 0
for i = 1:size+2
    input_image(i,1) = 0;
    input_image(i,size+2) = 0;
end

%Average the box filter and output the self smoothed picture
double temp
for i = 2:size+1
    for j = 2:size+1
           temp = double(1*input_image(i-1,j-1)+2*input_image(i-1,j)+1*input_image(i-1,j+1)+2*input_image(i,j-1)+4*input_image(i,j)+2*input_image(i,j+1)+ double(1*input_image(i+1,j-1))+double(2*input_image(i+1,j))+double(1*input_image(i+1,j+1)));
           self_smoothed_equalized_image_test_32_by_32(i-1,j-1) =  round(temp/16);
    end
end 

writematrix(image_test_32_by_32, 'image_test_64_by_64');
writematrix(self_smoothed_image_test_32_by_32, 'self_smoothed_image_test_64_by_64');
writematrix(equalized_image_test_32_by_32, 'equalized_image_test_64_by_64');
writematrix(equalized_self_smoothed_image_test_32_by_32, 'equalized_self_smoothed_image_test_64_by_64');
writematrix(self_smoothed_equalized_image_test_32_by_32, 'self_smoothed_equalized_image_test_64_by_64');


