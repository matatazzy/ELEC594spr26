% color calibration image exam
% this file is used for exam the camera seeting for the color calibration

%% load image
clear all; clc;close all;
filepath = 'Getdata/GrayCam/colorCali_hada2';
imgDir= 'Camshuttle1000ms_DMDexp3s' ;% Camshuttle60ms_DMDexp1s | Camshuttle40ms_DMDexp1s

files = dir(fullfile(filepath,imgDir,'*.png')); % 拼贴路径
assert(~isempty(files), 'No png found in: %s', imgDir);
fprintf('Found %d png files in %s\n', numel(files), fullfile(filepath, imgDir)); 

names = {files.name};

nShow = 12; % hadamard 个数 需要改变
hadamard = load('matlabcode/Hadamard12_A_final.mat');

nums = nan(numel(names),1); % numel(name):14
for i = 1:numel(names)
    tok = regexp(names{i}, '-(\d+)\.png$', 'tokens', 'once'); % 匹配 "-0003.png"
    assert(~isempty(tok), 'Filename does not match pattern "-####.png": %s', names{i});
    nums(i) = str2double(tok{1});
end

% 按编号排序
[~, idx] = sort(nums);
files = files(idx);

% read cell
imgs = cell(numel(files), 1);
for i = 1:numel(files)
    fp = fullfile(files(i).folder, files(i).name);
    imgs{i} = imread(fp);
end

fprintf('Loaded %d images. Index range: %d ~ %d\n', numel(imgs), nums(idx(1)), nums(idx(end)));


%% print image parameter
I = imgs{1};
[H,W,N] = size(I);
fprintf('image size: %d x %d x %d',H,W,N);
fprintf('Image class: %s\n', class(I));
fprintf('Min value: %g\n', min(I(:)));
fprintf('Max value: %g\n', max(I(:)));

cc = mat2gray(I);

figure;
imshow(cc);colormap("gray");axis on; hold on

r1=601;r2=1000; % 601 1000   | 750 1150 
c1=801;c2=1200; % 801 1200   | 601 1000

rectangle('Position', [c1, r1, c2-c1+1, r2-r1+1], ...
          'EdgeColor', 'r', 'LineWidth', 2);
title('ROI on cc');
hold off

% hist picture
% dd = cc(r1:r2,c1:c2);
% figure;
% hist(dd(:),128);


% ===== histogram for first 12 images in the same ROI =====
% 为了可比性：统一 bin 边界（因为 mat2gray 后都在 [0,1]）
nbins = 128;
edges = linspace(0, 1, nbins+1);

figure('Name','ROI histograms (first 12 images)','Color','w');
tiledlayout(3,4, 'Padding','compact','TileSpacing','compact');

for i = 1:nShow
    img = imgs{i};
    img_n = mat2gray(img);            % 归一化到 [0,1]
    roi = img_n(r1:r2, c1:c2);        % ROI
    
    nexttile;
    histogram(roi(:), edges);
    xlim([0 1]);
    grid on;
    
    % 你已经解析了编号 nums(idx(i))，标题用编号更清楚
    title(sprintf('img %02d  (#%d)', i, nums(idx(i))), 'Interpreter','none');
    xlabel('Intensity (mat2gray)');
    ylabel('Count');
end

%% pick one pixel in the image
r=700; c=1100; %| 900 800
Iw_p = I(r,c);

figure; 
imshow(I, []); axis on;
hold on

plot(c, r, 'r.', 'MarkerSize', 25);   % 注意顺序是 (x,y) = (col,row)

hold off

%% process data for imges ceils
Y = zeros(numel(imgs),1);
for i = 1:numel(names)
    img = imgs{i};
    img_n =mat2gray(img);
    Y(i)=img_n(r,c);
end

% load hadamard pattern matrix

S = hadamard.A_final; % 12x12 full-rand hadamard
A = [S;ones(1,size(S,2));zeros(1,size(S,2))]; % with all white and all black
    
A_double =double(A);
S_double = double(S);
%% Y=SX  S:12x12 Y:12x1
Y_crop = Y(1:nShow);
X = S_double \ Y_crop;

res = norm(S_double*X - Y_crop) / norm(Y_crop);
fprintf('Relative residual: %.3e\n', res);

Y_crop
X

figure;
plot(X, '-o', 'LineWidth', 1.5);
xlabel('Index');
ylabel('X value');
title('Recovered X');
grid on;