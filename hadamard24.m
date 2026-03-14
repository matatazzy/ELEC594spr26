clc; clear all; close all;
M = load('matlabcode/M_measurement.mat').M;

S = load('matlabcode/Hadamard24_A_final.mat').A_final; % 24x24
S = double(S);
rowMed = median(M, 2);      % 24×1，每一帧（pattern）整体亮度
M0 = M - rowMed;            % 去掉每帧偏置
N0 = S \ M0;

A = double(S);
fprintf('rank=%d, cond=%.2e\n', rank(A), cond(A));