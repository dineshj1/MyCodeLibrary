function model = LDNN_train(varargin)
% function usage:
%    [discriminants totalerror totalerrortest] = LDNN_train(xtrain, ytrain);
% OR [discriminants totalerror totalerrortest] = LDNN_train(xtrain, ytrain, xvalidation, yvalidation);
% OR [discriminants totalerror totalerrortest] = LDNN_train(xtrain, ytrain, options);
% OR [discriminants totalerror totalerrortest] = LDNN_train(xtrain, ytrain, xvalidation, yvalidation, options);
% Inputs:
%       xtrain: d by N training set ( d is number of attributes and N is
%               number of samples.
%       ytrain: 1 by N array of training labels.
%       xvalidation (optional): d by Nv validation set.
%       yvalidation (optional): 1 by Nv array of validation labels.
%       options:
%               options.epsilon = step size (default = 0.05).
%               options.momentum = momentum (default = 0.5).
%               options.maxepoch = maximum number of epochs (default = 25).
%               options.nGroup = Number of ORs (default = 5).
%               options.nDiscriminantPerGroup = Number of ANDs (default = 5).
%               options.cv = use a subset (10 percent) of training as validation set (default = 0).
%               options.ClusterDownsample = factor of downsampling data before clustering (default = 1).
%               options.cv_count = cross-validation count before stopping (default = 4).
%               options.kmeans_repeat = number of times that k-means run (kmeans_repeat = 5).

%               options.verbose= should I print out status


% Default hyper parameters:
epsilon = 0.05;
momentum = 0.5;
maxepoch = 25;
nGroup = 5;
nDiscriminantPerGroup = 5;
cv = 0;
verbose=1;
ClusterDownsample = 1;
cv_count = 4;
kmeans_repeat = 5;

if nargin < 2
    error('At least two input arguments are required');
elseif nargin==2
    xtrain = varargin{1};
    ytrain = varargin{2};
elseif nargin==4
    xtrain = varargin{1};
    ytrain = varargin{2};    
    xvalid = varargin{3};
    yvalid = varargin{4};
    cv = 1;
elseif nargin > 5
    error('Too many input arguments');
end

if nargin==3
    xtrain = varargin{1};
    ytrain = varargin{2};    
    options = varargin{3};
    name = fieldnames(options);
elseif nargin==5;
    xtrain = varargin{1};
    ytrain = varargin{2};    
    xvalid = varargin{3};
    yvalid = varargin{4};    
    options = varargin{5};
    name = fieldnames(options);
    cv = 1;
end


if exist('name','var')
    for i = 1:length(name)
        switch name{i}
            case 'epsilon'
                epsilon = options.epsilon;
            case 'momentum'
                momentum = options.momentum;
            case 'maxepoch'
                maxepoch = options.maxepoch;
            case 'nGroup'
                nGroup = options.nGroup;
            case 'nDiscriminantPerGroup'
                nDiscriminantPerGroup = options.nDiscriminantPerGroup;
            case 'cv'
                cv = options.cv;
            case 'ClusterDownsample'
                ClusterDownsample = options.ClusterDownsample;
            case 'cv_count'
                cv_count = options.cv_count;
            case 'kmeans_repeat'
                kmeans_repeat = options.kmeans_repeat;
            case 'verbose'
                verbose = options.verbose;
            otherwise
                warning(['Undefined option' name{i} '...skipping']);
        end
    end
end



if (~exist('xvalid','var') && cv)
    fprintf('Using 10 percent of data for validation\n');
    npm = randperm(size(xtrain,2));
    nvalid = floor(.1*size(xtrain,2));
    xvalid = xtrain(:,npm(1:nvalid));
    yvalid = ytrain(:,npm(1:nvalid));
    xtrain = xtrain(:,npm(nvalid+1:end));
    ytrain = ytrain(:,npm(nvalid+1:end));
end
 

indexP = find(ytrain>0);
indexN = find(ytrain==0);

if verbose 
  fprintf('Run clustering...');
end

tic;

cP = multi_km (nGroup, xtrain(:,indexP(1:ClusterDownsample:end)),kmeans_repeat);
cN = multi_km (nDiscriminantPerGroup, xtrain(:,indexN(1:ClusterDownsample:end)),kmeans_repeat);

clTime = toc;
if verbose 
  fprintf('Done. It took %f  \n',clTime);
end

n = size(xtrain,2);
if verbose 
  fprintf('Number of training samples = %d \n',n);
end

discriminants = [];
centroids = [];
for p = 1:nGroup
    discriminants = [discriminants bsxfun(@minus,cP(:,p),cN)];
    centroids = [centroids 0.5*bsxfun(@plus,cP(:,p),cN)];
end;
discriminants = bsxfun(@rdivide,discriminants,sqrt(sum(discriminants.^2,1)));
discriminants = [discriminants;-sum(discriminants.*centroids,1)];

% discriminants = randn(size(xtrain,1)+1,nDiscriminantPerGroup*nGroup); %uncomment for random initialization

xtrain = [xtrain;ones(1,n)];
if exist('xvalid','var')
    xvalid = [xvalid;ones(1,length(yvalid))];
end

if ~exist('xvalid','var')
    xvalid = [];
    yvalid = [];
    cv = 0;
end

if verbose 
  fprintf('Running the network \n');
end
[discriminants, totalerror, totalerrortest, n_epochs] = UpdateDiscriminantsCV( xtrain, ytrain, discriminants,...
    maxepoch, nDiscriminantPerGroup, nGroup, epsilon, momentum, xvalid, yvalid, cv_count, cv);

if cv == 1
    model.totalerrorvalid = totalerrortest;
end

model.discriminants = discriminants;
model.totalerror = totalerror;
model.nGroup = nGroup;
model.nDiscriminantPerGroup = nDiscriminantPerGroup;
model.n_epochs = n_epochs;

