function [classifiers, results] = buildClassifiers(trainData, varargin)
  % trainData.X is an NxL matrix. Each row is an instance represented by L feature dimensions
  % trainData.Y is an NxM matrix. Each row is a set of M labels assigned to the corresponding instance
  % Beta is an LxM matrix. Each column shows the features selected for learning a classifier for the m'th label
  params.trainData = trainData; clear trainData;
  params.numInstances = size(params.trainData,1);
  params.numTargets = size(params.trainData.Y, 2);
  %params.numFeatures = size(params.trainData.X, 2);
  
  params = parseArgs(params, varargin);

  if ~isdeployed
    addpath(genpath('R2011a/third-party/SVMs/liblinear-1.93/'));
    addpath(genpath('R2011a/third-party/SVMs/libsvm-3.16/'));
  end
  if params.normFeat
    [params.trainData.X, normParams]=normalizeFeatures(params.trainData.X, struct('method', 'zscore'));
    for valSetNo=1:length(params.valData)
      params.valData{valSetNo}.X=normalizeFeatures(params.valData{valSetNo}.X, normParams);
    end
    for testSetNo=1:length(params.testData) % for each test set
      params.testData{testSetNo}.X=normalizeFeatures(params.testData{testSetNo}.X, normParams);    
    end
  end
  for i=1:params.numTargets
    fprintf('Attrib #%d: ', i);
    selFeat=find(abs(params.Beta(:,i))>1e-6); 
    if strcmpi(params.method, 'LibLinear')
      classifiers(i)=liblin_train(params.trainData.Y(:, i), sparse(params.trainData.X(:,selFeat)), params.liblin_train_args); 
    elseif strcmpi(params.method, 'LibSVM')
      classifiers(i)=libsvm_train(params.trainData.Y(:, i),params.trainData.X(:,selFeat), params.libsvm_train_args);       
    %elseif strcmpi(params.method, 'LinRegressionCoeff')
    %  classifiers(i).w=params.Beta(:,i)';
    %  classifiers(i).type=params.method;
    elseif strcmpi(params.method, 'Fei')
      classifiers(i).w=params.Beta(:,i)';
      classifiers(i).thresh=0;
      classifiers(i).type=params.method;
    elseif strcmpi(params.method, 'MALSARlog')
      classifiers(i).w=[params.Beta(:,i); params.bias(i)]';% setting this up to be identical to 'Fei'
      classifiers(i).thresh=0;
      classifiers(i).type=params.method;
    %elseif strcmpi(params.method, 'LogReg')
    %  % learn a logistic regression classifer? (using other methods apart from liblinear?)
    %  clear('T', 'Tw');
    %  T=1; T=sparse(T);  Tw=0; % arbitrary grouping
    %  tmpData=struct('X', params.trainData.X, 'Y', params.trainData.Y(:,i));
    %  [Beta_naive, obj_naive, time_naive] =performTGLasso(tmpData, T, Tw,params.logRegParams); 
    %  classifiers(i).w=Beta_naive(:,i)';
    %  classifiers(i).type=params.method;
    else
      error('Unrecognized method!');
    end

    results(i)=evalClassifier(classifiers(i), 'method', params.method, ...
      'trainData', params.trainData, 'valData', params.valData, 'testData', params.testData, ...
      'selFeat', selFeat, 'targetCol', i, 'hard', true, 'hardmethod', params.hardmethod, ...
      'exp_tstLabels', params.tstCls_attrib_mat, 'liblin_predict_args', params.liblin_predict_args, ...
      'libsvm_predict_args', params.libsvm_predict_args);
  end
end

function params = parseArgs(params, varargs)
  %params.Beta = ones(params.numFeatures, params.numTargets);
  params.valData={};
  params.testData={};
  params.method='LibLinear';
  %params.method='LibSVM';
  params.normFeat=true;
  params.liblin_train_args = '-s 2 -c 30 -q'; % L2 SVM is default   
  params.libsvm_train_args = '-s 0 -t 0 -c 30 -b 1 -q'; % L2 linear SVM is default   
  params.liblin_predict_args = ' -q'; % L2 SVM is default             
  params.libsvm_predict_args = ' -q'; % L2 SVM is default 

  % defining logistic regression parameters
  params.logRegParams.TGLmu = 10;
  params.logRegParams.TGLoption.maxiter=10000;
  params.logRegParams.TGLoption.threshold=1e-5;
  params.logRegParams.TGLoption.tol=1e-5;
  params.logRegParams.TGLlambda=0; %no regularization    

  defaultHardMethod=true;
  %params.hardmethod = 'LibLinear';

  if isempty(varargs{1})
    return
  elseif mod(size(varargs),2)~=0
    error('No of arguments must be even');
  end 
  for i=1:2:length(varargs)
    switch varargs{i}
      case 'Beta'
        params.Beta = varargs{i+1};
      case 'bias'
        params.bias = varargs{i+1};
      case 'valData'
        params.valData = varargs{i+1};
        if ~iscell(params.valData)
          params.valData={params.valData};
        end 
      case 'testData'
        params.testData = varargs{i+1};
        if ~iscell(params.testData)
          params.testData={params.testData};
        end
      case 'method'
        params.method = varargs{i+1};
      case 'liblin_train_args'
        params.liblin_train_args = varargs{i+1};
      case 'liblin_predict_args'
        params.liblin_predict_args=varargs{i+1};
      case 'libsvm_train_args'
        params.libsvm_train_args = varargs{i+1};
      case 'libsvm_predict_args'
        params.libsvm_predict_args=varargs{i+1};
      case 'normalize'
        params.normFeat=varargs{i+1};
      case 'logRegParams'
        params.logRegParams=varargs{i+1};
      case 'hardmethod'
        defaultHardMethod=false;
        params.hardmethod=varargs{i+1};
      case 'tstClsAttrAnnot'
        params.tstCls_attrib_mat=varargs{i+1};
      otherwise
        error(sprintf('Unrecognized argument %s \n', varargs{i}));
    end
  end
  if defaultHardMethod
    params.hardmethod=repmat({'LibLinear'}, length(params.testData), 1); 
  end
end

function [normalized, normParams] = normalizeFeatures(rawData, normParams)
  % normalizes rawData as normalized=(rawData-normParams.a)/normParams.b;
  % if normParams.method is 'range', then a and b are simply the columnwise min and range respectively
  % if normParams.method is 'zscore', then a and b are respectively the mean and the stdev
  try 
      normParams.method;
  catch
      normParams.method='zscore';
  end
  try
      normParams.removeNaN;
  catch
      normParams.removeNaN=true;
  end
  
  if strcmpi(normParams.method, 'range')
    try
      normParams.a;
      normParams.b;
    catch
      normParams.a=min(rawData);
      normParams.b=max(rawData)-min(rawData);
    end 
    normalized = (rawData-repmat(normParams.a, size(rawData,1),1))./repmat(normParams.b, size(rawData, 1),1);
  elseif strcmpi(normParams.method, 'zscore')
    try 
      normParams.a;
      normParams.b;
    catch
      [~, normParams.a normParams.b] = zscore(rawData);
    end
    normalized = (rawData - repmat(normParams.a,size(rawData,1),1))./(repmat(normParams.b, size(rawData,1),1)+eps);
  end
end
