clear all; clc;close all;
% Initialize an array to store images

%% load images
filepath = 'Getdata/GrayCam/ColorCali_hada24_standard';
imgDir= 'Lego_CamExp1500ms_gain_22_DMD3s_sourb' ;
files = dir(fullfile(filepath,imgDir,'*.png')); 

assert(~isempty(files), 'No png found in: %s', imgDir);
fprintf('Found %d png files in %s\n', numel(files), fullfile(filepath, imgDir)); 

names = {files.name};
nShow = 24; % key number

nums = nan(numel(names),1); 
for i = 1:numel(names)
    tok = regexp(names{i}, '-(\d+)\.png$', 'tokens', 'once'); 
    assert(~isempty(tok), 'Filename does not match pattern "-####.png": %s', names{i});
    nums(i) = str2double(tok{1});
end

[~, idx] = sort(nums); % as order
files = files(idx);


imgs = cell(numel(files), 1);% read cell
for i = 1:numel(files)
    fp = fullfile(files(i).folder, files(i).name);
    imgs{i} = imread(fp);
end
fprintf('Loaded %d images. Index range: %d ~ %d\n', numel(imgs), nums(idx(1)), nums(idx(end)));

% % Display the images
% figure('Color','w');
% tiledlayout(5,6,'TileSpacing','compact','Padding','compact');
% for i = 1:numel(imgs)
%     nexttile;
%     imshow(imgs{i});
%     if i == 25
%         title(sprintf('%d (white)', i), 'Interpreter','none');
%     elseif i == 26
%         title(sprintf('%d (dark)', i), 'Interpreter','none');
%     else
%         title(sprintf('%d', i), 'Interpreter','none');
%     end
% end
%% cropped image
dark = imgs{end};
dark_g = rgb2gray(im2double(dark));

%% process the first data
new_imgs = cell(nShow,1); % 把 1和2拼成all white 的 24x1 （不含bg）
new_imgs{1} = im2double(imgs{1})+ im2double(imgs{2});

for k = 2:24
    new_imgs{k} = im2double(imgs{k+1}); 
end
img_1st = rgb2gray(new_imgs{2}) - dark_g;
%% choose ROI
figure('Color','w');
imagesc(img_1st); axis image; colormap gray; colorbar;
title('Draw ROI on img\_crop, double-click to confirm');

h = drawrectangle('Color','y');
wait(h);                 % 等你双击确认
roi = round(h.Position); % [x y w h]
close;

% roi = [468 395 951 754]; 
fprintf('Selected ROI = [x=%d y=%d w=%d h=%d]\n', roi(1), roi(2), roi(3), roi(4));

%% 处理第一张第二张，以及删去dark

I = cell(nShow,1); % 减去背景的的原图
imgs_crop = cell(nShow,1); % 减去背景的ROI图

for i = 2:nShow

    I{i} = rgb2gray(new_imgs{i}) - dark_g;
    
    imgs_crop{i} = imcrop(I{i}, roi);

end

% show cropped image 
figure('Color','w');
tiledlayout(4,6,'TileSpacing','compact','Padding','compact');

for i = 1:numel(imgs_crop)
    nexttile;
    imshow(imgs_crop{i}, []); 
    title(sprintf('%02d', i), 'Interpreter','none');
end
%% 
% create measurement data
H = size(imgs_crop{1},1);
W = size(imgs_crop{1},2);

M = zeros(24,H*W);
for i = 1:24
    img = imgs_crop{i};
    M(i, :) = reshape(img, 1, []);
end
save('M_measurement.mat', 'M', '-v7.3');
%% M = SN
S01 = load('matlabcode/Hadamard24_A_final.mat').A_final; % 24x24
S01 = double(S01);

A = 2*S01 - 1;
A_ps = pinv(A);

N = A_ps\M;


%% get spectrum reconstruction
Spec = load('lambda_ch24.mat');
lambda_ch = Spec.lambda_ch;

cube = permute(reshape(N, [24, H, W]), [2, 3, 1]); % H×W×24

HSI = struct();
HSI.cube = cube;
HSI.lambda = lambda_ch(:);
HSI.order = 'ch1=longave';
HSI.size = size(cube);
save('HSI_cube.mat','HSI','-v7.3');


%% window spectrum reconstruction

img_show = imgs_crop{1};
figure;
imagesc(img_show); axis image; colormap gray; colorbar;
title('Draw a window ROI on imgs\_crop{1}, double-click to confirm');
h = drawrectangle('Color','y');
wait(h);                      % 等你双击确认
roi_win = round(h.Position);  % [x y w h] in cropped coordinates

% clamp to bounds
x = max(1, roi_win(1));
y = max(1, roi_win(2));
x2 = min(W, x + roi_win(3));
y2 = min(H, y + roi_win(4));
roi_win = [x y (x2-x) (y2-y)];

mask = false(H,W);
mask(y:y2, x:x2) = true; % 在imgs_crop的基础上，window内是1，其余是0

fprintf('ROI: x=%d, y=%d, x2=%d, y2=%d, w=%d, h=%d\n', ...
        x, y, x2, y2, x2-x, y2-y);
% cube: H×W×24
% mask: H×W logical (window区域为true)

C = size(cube,3);

spec_med = zeros(C,1);
for k = 1:C
    imgk = cube(:,:,k);
    spec_med(k) = median(imgk(mask),'omitnan');
end

figure('Color','w');
plot(lambda_ch, spec_med, '-o', 'LineWidth', 2);
grid on; xlabel('Wavelength (nm)'); ylabel('Median intensity');
title('Window median spectrum (ch1 = long wavelength)');
