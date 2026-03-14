clc;
clear;

% Image size
H = 1080;
W = 1920;

% Stripe parameters
n_stripes = 24;
stripeW   = 49;
effW      = n_stripes * stripeW;   % 1176

% 起始列（如需居中可改）
x0 = 1;
% 若想居中用下面这行替换：
% x0 = floor((W - effW)/2) + 1;

% -------- 保存路径 --------
outFolder = fullfile('DMD pattern', 'Raster', 'Hadamard24');

if ~exist(outFolder,'dir')
    mkdir(outFolder);
end

% -------- 生成条纹 --------
for k = 1:n_stripes
    
    img = zeros(H, W, 'uint8');
    
    col_start = x0 + (k-1)*stripeW;
    col_end   = col_start + stripeW - 1;
    
    img(:, col_start:col_end) = 255;
    
    filename = sprintf('%02d.bmp', k);
    imwrite(img, fullfile(outFolder, filename));
    
end

disp('24 张 raster 条纹已生成完成.');