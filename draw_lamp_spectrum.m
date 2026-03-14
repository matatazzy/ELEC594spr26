% read spectrum 

%% load image
close all;clear all; clc;
filepath = 'Getdata/GrayCam/colorCali_hada2';
imgDir= 'all white lamp spectrum.txt' ;% Camshuttle60ms_DMDexp1s | Camshuttle40ms_DMDexp1s

fname = fullfile(filepath,imgDir); % 拼贴路径

M = readmatrix(fname);
wavelength = M(:,1);
intensity = M(:,2);


figure;
plot(wavelength, intensity, 'LineWidth', 1.2);
xlabel('Wavelength (nm)');
ylabel('Intensity');
title('Spectrum');
grid on;