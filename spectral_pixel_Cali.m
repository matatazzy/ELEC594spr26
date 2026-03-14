folder = fullfile('Getdata','Spectrometer','raster_hadamard24_1176px');

files = dir(fullfile(folder,'1_*.txt'));
assert(~isempty(files), 'No files found in %s', folder);

% 按编号排序：1_00, 1_01, ...
names = {files.name};
idx = nan(numel(names),1);
for k = 1:numel(names)
    tok = regexp(names{k}, '^1_(\d+)\.txt$', 'tokens', 'once');
    if ~isempty(tok)
        idx(k) = str2double(tok{1});
    end
end
[~,ord] = sort(idx);
files = files(ord);

% 读第一个文件拿波长轴
M0 = readmatrix(fullfile(folder, files(1).name));
lambda = M0(:,1);
L = numel(lambda);

K = numel(files);
I = zeros(L, K);
I(:,1) = M0(:,2);

% 读剩下文件
for k = 2:K
    Mk = readmatrix(fullfile(folder, files(k).name));

    % 可选：检查波长轴是否一致
    if ~isequal(Mk(:,1), lambda)
        warning('Wavelength grid differs in %s (will still load intensity).', files(k).name);
    end

    I(:,k) = Mk(:,2);
end

figure('Color','w');
plot(lambda, I, 'LineWidth', 1);
grid on;
xlabel('Wavelength'); ylabel('Intensity');
title('All spectra: 1\_00 ... 1\_23', 'Interpreter','none');

[maxI, idxMax] = max(I, [], 1);          % 1×K
lambdaMax = lambda(idxMax);             % 1×K

disp([ (0:K-1)' , lambdaMax(:), maxI(:) ]);  % [index, peak_lambda, peak_intensity]

K = size(I, 2);                 % 应该是24

% 每条光谱的最大值及其索引
[~, idxMax] = max(I, [], 1);    % 1×K
lambdaMax = lambda(idxMax);     % 1×K

channels = 1:K;

figure('Color','w');
plot(channels, lambdaMax, '-o', 'LineWidth', 2, 'MarkerSize', 6);
grid on;
xlabel('Spectral channel (1-24)');
ylabel('Peak wavelength');
title('Peak wavelength of each spectrum');
xticks(1:K);

lambda_ch = lambdaMax(:);   % 确保是 24×1
save('lambda_ch24.mat', 'lambda_ch');