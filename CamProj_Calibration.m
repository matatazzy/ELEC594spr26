%% graycode 解码
% pose_i_h → 得到 projector X
% pose_i_v → 得到 projector Y

function [coordMap, validMask, bits, binaryBits] = decodeGraycodeFolder(folderPath)

files = dir(fullfile(folderPath, '*.png'));
assert(~isempty(files), 'No PNG files found.');

% 按文件名排序
[~, idx] = sort({files.name});
files = files(idx);

assert(numel(files) == 10, 'Expected 10 images: black + 8 graycode + white.');

% --- read images ---
Iblack = im2double(imread(fullfile(files(1).folder, files(1).name)));
Iwhite = im2double(imread(fullfile(files(end).folder, files(end).name)));

if size(Iblack,3) == 3
    Iblack = rgb2gray(Iblack);
end
if size(Iwhite,3) == 3
    Iwhite = rgb2gray(Iwhite);
end

[H,W] = size(Iblack);
Igray = zeros(H,W,8);

for k = 1:8
    Ik = im2double(imread(fullfile(files(k+1).folder, files(k+1).name)));
    if size(Ik,3) == 3
        Ik = rgb2gray(Ik);
    end
    Igray(:,:,k) = Ik;
end

% --- valid mask from black/white contrast ---
contrast = Iwhite - Iblack;
validMask = contrast > 0.05;   % threshold can be tuned

% --- threshold each graycode bit ---
thresh = (Iblack + Iwhite) / 2;
bits = false(H,W,8);

for k = 1:8
    bits(:,:,k) = Igray(:,:,k) > thresh;
end

% --- gray to binary ---
binaryBits = false(H,W,8);
binaryBits(:,:,1) = bits(:,:,1);

for k = 2:8
    binaryBits(:,:,k) = xor(binaryBits(:,:,k-1), bits(:,:,k));
end

% --- binary to decimal ---
coordMap = zeros(H,W);

for k = 1:8
    coordMap = coordMap + double(binaryBits(:,:,k)) * 2^(8-k);
end

coordMap(~validMask) = NaN;

end

folder_h = 'Getdata/GrayCam/3D_reconstruction_Cali/Graycode8bit_hw/pose1_h';
[projX, maskX] = decodeGraycodeFolder(folder_h);

folder_v = 'Getdata/GrayCam/3D_reconstruction_Cali/Graycode8bit_hw/pose1_v';
[projY, maskY] = decodeGraycodeFolder(folder_v);



%% 对每个pose
% 检测所有可见棋盘格脚点在camera中的位置
imagePoints_cam = detectCheckerboardPoints(I);

% 用gray code解码得到整幅图的projector坐标map
projXmap, projYmap
%再角点位置插值得到projector坐标
imagePoints_proj = [u_p, v_p];
% 给这些角点赋予 cube 坐标系下的 3D world points
worldPoints3D = [X, Y, Z];


% data(i).worldPoints3D    % Nx3
% data(i).camPoints        % Nx2
% data(i).projPoints       % Nx2
% data(i).faceID           % Nx1, 可选

%% up = interp2(projXmap,uc,vc)
% vp = interp2(projYmap,uc,vc)



% camera pixel  (uc vc)
% projector pixel (up vp)
% world point (X Y Z)
%%