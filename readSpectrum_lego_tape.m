% plot detected spectrum of lego and tape
clear; clc; close all;

folder = fullfile('Getdata','Spectrometer','color_groundtruth');
files = dir(fullfile(folder,'*.txt'));
assert(~isempty(files), 'No .txt found in %s', folder);

lo=450;
hi=700;
for i = 1:numel(files)
    fname = fullfile(files(i).folder, files(i).name);

    % 读取两列：lambda / intensity
    M = readmatrix(fname);  % 适用于你这种"左波长右强度"的纯数字txt
    assert(size(M,2) >= 2, 'File %s does not have >=2 columns', files(i).name);

    lambda = M(:,1);
    inten  = M(:,2);

    keep = (lambda >= lo) & (lambda <= hi);
    lambda = lambda(keep);
    inten  = inten(keep);

    figure('Color','w');
    plot(lambda, inten, 'LineWidth', 2);
    grid on;
    xlabel('Wavelength (nm)');
    ylabel('Intensity');
    title(strrep(files(i).name, '_', '\_'));  % 防止下划线变下标
end