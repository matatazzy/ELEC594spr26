%% this file is used to create pattern for color calibration of HSI
% the DMD resolution : 1080 x 1920 
% the width we use of DMD : [1080] x [0-1176] 
% I devided the 1176 into 12 channel, wavelength: 450 ~ 650
% now I careate my color calibration pattern
clc;
clear;

H    = 1080;
W    = 1920;
n_ch = 24;    % 12
chW  = 49; % 98
x0   = 1; % start column in matlab
effW = n_ch * chW; % 1176
x1   = x0 + effW -1;
white_channel = n_ch/2;


outFolder = sprintf('DMD pattern/Hadamard Pattern/hadamard%02d', n_ch);
if ~exist(outFolder,'dir'); mkdir(outFolder); end

imgW = zeros(H,W,'uint8');
imgW(:,x0:x1) = 255;

% each row has exactly n_ch / 2 ones (bright channels)
h = hadamard(n_ch);

% 11 rows from Hadamard[2:12]
S11 = h(2:end, :);
A11 = uint8((S11 + 1)/2);

% search for the 12th balanced row to make rank=12
bestA = [];
bestCond = inf;
maxTries = 20000;

for t = 1:maxTries
    idx = randperm(n_ch,white_channel); % 在12 个 channel 里面随机选 6 个 channel
    r = zeros(1,n_ch); % 把选出来的数改成channel
    r(idx) = 1; % 把这个留个数对应的 channel 置成 1

    A = [A11;r];

    % full-rank check
    if rank(double(A)) == n_ch  % 注意检查
        c =cond(double(A)); % L2
        if c < bestCond
            bestCond = c;
            bestA = A;
        end
    end
end

if isempty(bestA)
    error('Failed to find a full-rank balanced %dx%d matrix. Increase maxTries.', n_ch, n_ch);
end

A_final = bestA; %  hadamard without white
fprintf('Found balanced full-rank coding. cond(S)=%.2f\n',bestCond)
fprintf('Ones per row (should all be 6): '); disp(sum(A_final,2));

for r = 1: n_ch
    img = zeros(H,W,'uint8');

    for c = 1:n_ch

        xs = x0 + (c-1) * chW;
        xe = xs + chW - 1;

        img(:,xs:xe) = uint8(255 * A_final(r,c));
    end

    imwrite(img,fullfile(outFolder,sprintf('%02d.bmp',r)));
end

fprintf('Save patterns to : %s\n',outFolder);

A_final_with_white = [ones(1, n_ch, 'uint8'); A_final];  % 13x12

disp(A_final_with_white);

fprintf('Saved %d patterns to: %s\n', size(A_final_with_white,1), outFolder);
disp(A_final);
save(sprintf('Hadamard%d_A_final.mat',n_ch),'A_final');

%% ---- Generate txt file listing 01.bmp ~ 24.bmp ----
txtName = fullfile(outFolder, 'pattern_index.txt');
fid = fopen(txtName, 'w');

if fid == -1
    error('Cannot create txt file.');
end

for k = 1:n_ch
    fprintf(fid, '%02d.bmp\n', k);
end

fclose(fid);

fprintf('Generated pattern index file: %s\n', txtName);


