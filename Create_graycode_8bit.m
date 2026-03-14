%% this file is used to create 8-bit Graycode patterns
% DMD resolution: 1080 x 1920
% Active projection region: 1080 x 1176
% Graycode is generated along row dimension (1080)
% 8-bit means 1080 rows are quantized into 256 Graycode levels

clc;
clear all;
close all;

H    = 1080;
W    = 1920;

effW = 1176;
x0   = 1;
x1   = x0 + effW - 1;

nBits = 8;
nLevels = 2^nBits;   % 256
nTotal = nBits + 2;  % black + bits + white

outFolder = sprintf('DMD pattern/Graycode Pattern/graycode_%02dbit_row1080', nBits);
if ~exist(outFolder, 'dir')
    mkdir(outFolder);
end

allPatterns = zeros(H, W, nTotal, 'uint8');
fileNames = strings(nTotal,1);

%% Step 1: map 1080 rows -> 256 quantized levels
rowIdx = 0:H-1;
qIdx = floor(rowIdx * nLevels / H);   % values in [0,255]

%% Step 2: Graycode of quantized index
gray = bitxor(uint16(qIdx), bitshift(uint16(qIdx), -1));

%% 00: black
img_black = zeros(H, W, 'uint8');
allPatterns(:,:,1) = img_black;
fileNames(1) = "00_black.bmp";
imwrite(img_black, fullfile(outFolder, fileNames(1)));

%% 01 ~ 08: bit07 ~ bit00
for b = 1:nBits
    bitplane = bitget(gray, nBits - b + 1);   % H x 1
    
    bitCol = uint8(bitplane(:));
    stripeRegion = uint8(255 * repmat(bitCol, 1, effW));
    
    img = zeros(H, W, 'uint8');
    img(:, x0:x1) = stripeRegion;
    
    idx = b + 1;
    allPatterns(:,:,idx) = img;
    fileNames(idx) = sprintf('%02d_bit%02d.bmp', idx-1, nBits-b);
    
    imwrite(img, fullfile(outFolder, fileNames(idx)));
end

%% last: white
img_white = zeros(H, W, 'uint8');
img_white(:, x0:x1) = 255;
allPatterns(:,:,nTotal) = img_white;
fileNames(nTotal) = sprintf('%02d_white.bmp', nTotal-1);
imwrite(img_white, fullfile(outFolder, fileNames(nTotal)));

fprintf('Saved black + %d bit planes + white to:\n%s\n', nBits, outFolder);

%% txt file
txtName = fullfile(outFolder, 'pattern_index.txt');
fid = fopen(txtName, 'w');
if fid == -1
    error('Cannot create txt file.');
end
for k = 1:nTotal
    fprintf(fid, '%s\n', fileNames(k));
end
fclose(fid);

fprintf('Generated pattern index file: %s\n', txtName);

%% display
figure('Name','Graycode Patterns Overview','NumberTitle','off');
nCols = 4;
nRows = ceil(nTotal / nCols);

for k = 1:nTotal
    subplot(nRows, nCols, k);
    imshow(allPatterns(:,:,k), []);
    title(strrep(fileNames(k), '_', '\_'), 'FontSize', 9);
end

sgtitle(sprintf('%d-bit Graycode patterns on row dimension (1080)', nBits));