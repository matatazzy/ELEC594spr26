% this file aim to create standerd hadamart pattern
%% this file is used to create pattern for color calibration of HSI
% the DMD resolution : 1080 x 1920 
% the width we use of DMD : [1080] x [0-1176] 
% I devided the 1176 into 12 channel, wavelength: 450 ~ 650
% now I careate my color calibration pattern
clc;
clear all;

H    = 1080;
W    = 1920;
n_ch = 24;
chW  = 49;
x0   = 1;                  % start column in MATLAB
effW = n_ch * chW;         % 1176
x1   = x0 + effW - 1;

outFolder = sprintf('DMD pattern/Hadamard Pattern/hadamard%02d_Stand', n_ch);
if ~exist(outFolder, 'dir')
    mkdir(outFolder);
end

% Generate standard Hadamard matrix in {-1, +1}
h = hadamard(n_ch);

% Convert to {0,1}
H01 = uint8((h + 1) / 2);

% Add two custom rows at the top, remove the original first row
v1 = uint8([ones(1,12),  zeros(1,12)]);
v2 = uint8([zeros(1,12), ones(1,12)]);

H_2524 = [v1; v2; H01(2:end,:)];   % 25 x 24

% Check size
fprintf('Size of H_2524: %d x %d\n', size(H_2524,1), size(H_2524,2));

% Generate and save bmp patterns
for r = 1:size(H_2524, 1)
    img = zeros(H, W, 'uint8');

    for c = 1:n_ch
        xs = x0 + (c - 1) * chW;
        xe = xs + chW - 1;
        img(:, xs:xe) = uint8(255 * H_2524(r, c));
    end

    imwrite(img, fullfile(outFolder, sprintf('%02d.bmp', r)));
end

fprintf('Saved %d patterns to: %s\n', size(H_2524,1), outFolder);

% Display matrix
disp(H_2524);

% Save matrix
save(sprintf('Hadamard%d.mat', n_ch), 'H01');

% %% ---- Generate txt file listing bmp names ----
% txtName = fullfile(outFolder, 'pattern_index.txt');
% fid = fopen(txtName, 'w');
% 
% if fid == -1
%     error('Cannot create txt file.');
% end
% 
% for k = 1:size(H_2524, 1)
%     fprintf(fid, '%02d.bmp\n', k);
% end
% 
% fclose(fid);
% 
% fprintf('Generated pattern index file: %s\n', txtName);