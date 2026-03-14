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

% Display the images
figure('Color','w');
tiledlayout(5,6,'TileSpacing','compact','Padding','compact');
for i = 1:numel(imgs)
    nexttile;
    imshow(imgs{i});
    if i == 25
        title(sprintf('%d (white)', i), 'Interpreter','none');
    elseif i == 26
        title(sprintf('%d (dark)', i), 'Interpreter','none');
    else
        title(sprintf('%d', i), 'Interpreter','none');
    end
end
%% image pre-process

% background
dark = imgs{end};
dark_g = rgb2gray(im2double(dark));

%% build 24 corrected images directly

I = cell(nShow,1);   % 这里 I 里存的就是"已经减完背景"的 24 张图

% 第1张：两次半曝光拼成完整 all-white，同时减两次 bg
I{1} = (rgb2gray(im2double(imgs{1})) - dark_g) + ...
       (rgb2gray(im2double(imgs{2})) - dark_g);

% 第2~24张：对应原来的 imgs{3} ~ imgs{25}
for k = 2:nShow
    I{k} = rgb2gray(im2double(imgs{k+1})) - dark_g;
end

figure('Color','w');
tiledlayout(4,6,'TileSpacing','compact','Padding','compact');
for k = 1:nShow
    nexttile;
    imshow(I{k}, []);
    title(sprintf('%02d', k), 'Interpreter','none');
end

%% Crop image 
img_1st = I{1};

figure('Color','w');
imagesc(img_1st); axis image; colormap gray; colorbar;
title('Draw ROI on img\_crop, double-click to confirm');

h = drawrectangle('Color','y');
wait(h);                 % 等你双击确认
roi = round(h.Position); % [x y w h]
close;

% roi = [468 395 951 754]; 
fprintf('Selected ROI = [x=%d y=%d w=%d h=%d]\n', roi(1), roi(2), roi(3), roi(4));

%% crop all correct images
imgs_crop = cell(nShow,1);
for k = 1:nShow
    imgs_crop{k} = imcrop(I{k}, roi);
end

% show cropped correct image
figure('Color','w');
tiledlayout(4,6,'TileSpacing','compact','Padding','compact');

for k = 1:nShow
    nexttile;
    imshow(imgs_crop{k}, []);
    title(sprintf('%02d', k), 'Interpreter','none');
end
%% 
% create measurement data
h = size(imgs_crop{1},1);
w = size(imgs_crop{1},2);

M = zeros(24,h*w);
for i = 1:24
    img = imgs_crop{i};
    M(i, :) = reshape(img, 1, []);
end
save('M_measurement.mat', 'M', '-v7.3');
%% M = SN
H_s = hadamard(24);
H_10 = (H_s +1) /2;
H = double(H_10);

N = H\M;


%% get spectrum reconstruction
Spec = load('matlabcode/hadamard/lambda_ch24.mat');
lambda_ch = Spec.lambda_ch;

cube = permute(reshape(N, [24, h, w]), [2, 3, 1]); % H×W×24

HSI = struct();
HSI.cube = cube;
HSI.lambda = lambda_ch(:);
HSI.order = 'ch1=longave';
HSI.size = size(cube);
save('HSI_cube.mat','HSI','-v7.3');


%% 
keepGoing = true;

while keepGoing
    img_show = imgs_crop{1};
    figure('Color','w');
    imagesc(img_show); axis image; colormap gray; colorbar;
    title('Draw a window ROI on imgs\_crop{1}, double-click to confirm');

    hRect = drawrectangle('Color','y');
    wait(hRect);
    roi_win = round(hRect.Position);   % [x y w h]
    
    % clamp to bounds
    x  = max(1, roi_win(1));
    y  = max(1, roi_win(2));
    x2 = min(w, x + roi_win(3));
    y2 = min(h, y + roi_win(4));

    mask = false(h,w);
    mask(y:y2, x:x2) = true;

    fprintf('ROI: x=%d, y=%d, x2=%d, y2=%d, w=%d, h=%d\n', ...
        x, y, x2, y2, x2-x+1, y2-y+1);

    C = size(cube,3);
    spec_med = zeros(C,1);

    for k = 1:C
        imgk = cube(:,:,k);
        spec_med(k) = median(imgk(mask), 'omitnan');
    end

    figure('Color','w');
    plot(lambda_ch, spec_med, '-o', 'LineWidth', 2);
    grid on;
    xlabel('Wavelength (nm)');
    ylabel('Median intensity');
    title(sprintf('Window median spectrum: x=%d, y=%d, w=%d, h=%d', ...
        x, y, x2-x+1, y2-y+1));

    choice = questdlg('Select another ROI?', ...
        'Continue ROI selection', ...
        'Yes', 'No', 'Yes');

    if strcmp(choice, 'No')
        keepGoing = false;
    end
end

% %% window spectrum reconstruction
% 
% img_show = imgs_crop{1};
% figure;
% imagesc(img_show); axis image; colormap gray; colorbar;
% title('Draw a window ROI on imgs\_crop{1}, double-click to confirm');
% 
% hRect = drawrectangle('Color','y');
% wait(hRect);
% roi_win = round(hRect.Position);  % [x y w h] in cropped coordinates
% 
% % clamp to bounds
% x = max(1, roi_win(1));
% y = max(1, roi_win(2));
% x2 = min(w, x + roi_win(3));
% y2 = min(h, y + roi_win(4));
% roi_win = [x y (x2-x) (y2-y)];
% 
% mask = false(h,w);
% mask(y:y2, x:x2) = true; % 在imgs_crop的基础上，window内是1，其余是0
% 
% fprintf('ROI: x=%d, y=%d, x2=%d, y2=%d, w=%d, h=%d\n', ...
%         x, y, x2, y2, x2-x, y2-y);
% % cube: H×W×24
% % mask: H×W logical (window区域为true)
% 
% C = size(cube,3);
% 
% spec_med = zeros(C,1);
% for k = 1:C
%     imgk = cube(:,:,k);
%     spec_med(k) = median(imgk(mask),'omitnan');
% end
% 
% figure('Color','w');
% plot(lambda_ch, spec_med, '-o', 'LineWidth', 2);
% grid on; xlabel('Wavelength (nm)'); ylabel('Median intensity');
% title('Window median spectrum (ch1 = long wavelength)');
