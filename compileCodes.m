%    addpath(genpath('~/.matlab/R2011a/third-party/'));
%    addpath(genpath('R2011a/third-party/vlfeat-0.9.16/'));
%    %addpath(genpath('R2011a/'));
%    %addpath(genpath('matlab_mtl'));
%    
% %    addpath(genpath('som/'));
% %    mkdir('mcc/dataset_SOM/');
% %    mcc -mCv dataset_SOM -d mcc/dataset_SOM/
% %    system('mcc/dataset_SOM/dataset_SOM');
% %    
% %    addpath(genpath('som/'));
% %    mkdir('mcc/evalSOM/');
% %    mcc -mCv evalSOM -d mcc/evalSOM/
% %    system('mcc/evalSOM/evalSOM');
% 
% %   addpath(genpath('computeFeatures/'));
% %   mkdir('mcc/computeBirdFeatures/');
% %   mcc -mCv computeBirdFeatures -d mcc/computeBirdFeatures/
% %   system('mcc/computeBirdFeatures/computeBirdFeatures ');
% 
%    addpath(genpath('R2011a/third-party/SVMs/liblinear-1.93/'));
%    addpath(genpath('R2011a/third-party/utils/'));
%    addpath(genpath('TGLasso/')); 
%    addpath(genpath('matlab_mtl/'));  
%    addpath(genpath('MALSAR/'));  

%   addLib;
%   mcc -mCv general_TG -d mcc/
%   system('mcc/general_TG cluster 0 process 0 data Farhadi_PCA figFormat png lambdaList [1] w1List [0] w2List [1] muList [1] maxiter 2 selMethodNames "{''proposed'',''farhadi''}"');
%   fprintf('Changing permissions\n');
%   FID=fopen('Recompiled.txt', 'w'); % To keep track of compiled time
%   fprintf(FID, 'Executable compiled at %s', datestr(now,'dd-mm-yyyy HH:MM:SS'));  
%   fclose(FID);
%   system('chmod 772 -R mcc/ --quiet');

   addLib;
   mcc -mCv SVMTrials -d mcc/
   system('mcc/SVMTrials cluster 0 process 0 data Farhadi_PCA figFormat png lambdaList [1] w1List [0] w2List [1] muList [1] maxiter 2 selMethodNames "{''proposed'',''farhadi''}"');
   fprintf('Changing permissions\n');
   system('chmod 772 -R mcc/ --quiet'); 
