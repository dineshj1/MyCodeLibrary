clc
clear

fprintf('Training Ionosphere dataset 50 times using LDNN (Press space to continue):');
pause
fprintf('\n');

load('datasets/ionosphere.mat');
param.nGroup = 1;  % number of ORs in final DNF
param.nDiscriminantPerGroup = 60; % number of ANDs in every group
param.epsilon = 0.1;
param.maxepoch = 40;
param.cv_count = 4;
param.kmeans_repeat = 50;
param.norm_type = 2;
% xtrain is numFeatures \times numSamples
% ytrain is 1 \times numSamples 
prepare( xtrain, ytrain, xtest, ytest, xcv, ycv, param )

fprintf('Training PIMA diabetes dataset 50 times using LDNN (Press space to continue):');
pause
fprintf('\n');

load('datasets/diabetes.mat');
param.nGroup = 6;
param.nDiscriminantPerGroup = 10;
param.epsilon = 0.02;
param.maxepoch = 60;
param.cv_count = 5;
param.kmeans_repeat = 15;
param.norm_type = 2;
prepare( xtrain, ytrain, xtest, ytest, xcv, ycv, param )

fprintf('Training German credit dataset 50 times using LDNN (Press space to continue):');
pause
fprintf('\n');

load('datasets/german.mat');
param.nGroup = 6;
param.nDiscriminantPerGroup = 1;
param.epsilon = 0.05;
param.maxepoch = 15;
param.cv_count = 3;
param.kmeans_repeat = 70;
param.norm_type = 2;
prepare( xtrain, ytrain, xtest, ytest, xcv, ycv, param )

fprintf('Training Breast cancer dataset 50 times using LDNN (Press space to continue):');
pause
fprintf('\n');

load('datasets/cancer.mat');
param.nGroup = 2;
param.nDiscriminantPerGroup = 1;
param.epsilon = 0.05;
param.maxepoch = 12;
param.cv_count = 4;
param.kmeans_repeat = 100;
param.norm_type = 1;
prepare( xtrain, ytrain, xtest, ytest, xcv, ycv, param )


