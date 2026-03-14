%% this file is used to create 11-bit Graycode patterns
% DMD resolution: 1080 x 1920
% Active projection region: 1080 x 1176 (columns 1:1176)
% Graycode is generated along the 1080 dimension (row direction)
% Therefore, the patterns are horizontal stripes
% Outside the Graycode region, pixels remain black
%
% Frame order:
%   00: all black
%   01~11: bit10 ~ bit00
%   12: all white

clc;
clear all;
close all;

H    = 1080;
W    = 1920;

effW = 1176;
x0   = 1;
x1   = x0 + effW - 1;

nBits = 11;
nTotal = nBits + 2;   % black + 11 bit planes + white

outFolder = sprintf('DMD pattern/Graycode Pattern/graycode_%02dbit_row1080x1176', nBits);
if ~exist(outFolder, 'dir')
    mkdir(outFolder);
end

%% Generate Graycode for row indices 0 ~ H-1
rowIdx = uint16(0:H-1);
gray   = bitxor(rowIdx, bitshift(rowIdx, -1));

% store all patterns
allPatterns = zeros(H, W, nTotal, 'uint8');
fileNames = strings(nTotal, 1);

%% 00: all black
img_black = zeros(H, W, 'uint8');
allPatterns(:,:,1) = img_black;
fileNames(1) = "00_black.bmp";
imwrite(img_black, fullfile(outFolder, fileNames(1)));

%% 01 ~ 11: Graycode bit planes
for b = 1:nBits
    % b = 1 -> bit10
    % b = 11 -> bit00
    bitplane = bitget(gray, nBits - b + 1);   % H x 1

    % replicate along active width
    bitCol = uint8(bitplane(:));
    stripeRegion = uint8(255 * repmat(bitCol, 1, effW));

    % full DMD image, outside active region remains black
    img = zeros(H, W, 'uint8');
    img(:, x0:x1) = stripeRegion;

    idx = b + 1;   % file frame index
    allPatterns(:,:,idx) = img;
    fileNames(idx) = sprintf('%02d_bit%02d.bmp', idx-1, nBits-b);

    imwrite(img, fullfile(outFolder, fileNames(idx)));
end

%% 12: all white in active region only
img_white = zeros(H, W, 'uint8');
img_white(:, x0:x1) = 255;
allPatterns(:,:,nTotal) = img_white;
fileNames(nTotal) = sprintf('%02d_white.bmp', nTotal-1);
imwrite(img_white, fullfile(outFolder, fileNames(nTotal)));

fprintf('Saved black + %d bit planes + white to:\n%s\n', nBits, outFolder);

%% ---- Generate txt file listing bmp names ----
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

%% ---- Display all patterns ----
figure('Name','Graycode Patterns Overview','NumberTitle','off');

nCols = 4;
nRows = ceil(nTotal / nCols);

for k = 1:nTotal
    subplot(nRows, nCols, k);
    imshow(allPatterns(:,:,k), []);
    title(strrep(fileNames(k), '_', '\_'), 'FontSize', 9);
end

sgtitle(sprintf('%d-bit Graycode patterns on row dimension (1080)', nBits));
