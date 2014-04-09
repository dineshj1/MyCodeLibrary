function results = evalClassifier(model, varargin)
  params = parseArgs(varargin);
  if ~isdeployed
    warning off;
    addpath(genpath('R2011a/third-party/vlfeat-0.9.16/'));
    %warning on;
  end
  results = [];
  assert(iscell(params.valData));
  for valSetNo=1:length(params.valData) % for each validation set
    if ~isempty(params.valData{valSetNo})
        results.val(valSetNo)=classifyData(model, params.valData{valSetNo}, params);
    end 
  end

  assert(iscell(params.testData));
  for testSetNo=1:length(params.testData) % for each test set
    if ~isempty(params.testData{testSetNo})
      results.test(testSetNo)=classifyData(model, params.testData{testSetNo}, params);
    end
    % hard cases testing
    if params.hardCaseTesting && ~isempty(params.trainData) && ~isempty(params.testData{testSetNo})
      % Identifying hard cases
      if strcmpi(params.HARD_method{testSetNo}, 'KNN') 
         % % Test using predictability with a KNN Classifier
        if ~isdeployed, addpath(genpath('som/')); end
        [~, details] = knnclassify(eye(params.numAttr-1),...
            [params.trainData.Y(:,setdiff(1:params.numAttr, params.targetCol)) params.trainData.Z]', params.trainData.Y(:, params.targetCol)', ...
            [params.testData{testSetNo}.Y(:,setdiff(1:params.numAttr, params.targetCol)) params.testData{testSetNo}.Z]', params.testData{testSetNo}.Y(:, params.targetCol)', ...
            params.k, false);
        pred = details.lTe2(end,:)';
        correctPred=(pred==params.testData{testSetNo}.Y(:,params.targetCol));  
        hardInd = ~correctPred;
      elseif strcmpi(params.HARD_method{testSetNo}, 'GMM') % always fails!
        % find k means clusters to initialize
        idx = kmeans([params.trainData.Y params.trainData.Z], params.k); 
        % infer a GMM on all attributes training data
        gmm_dist=gmdistribution.fit([params.trainData.Y params.trainData.Z], params.k, 'Start', idx); % for this option, k refers to the number of gaussians
        % predict the likelihood of test data 
        likelihoods=pdf(gmm_dist,[params.testData{testSetNo}.Y params.testData{testSetNo}.Z]);
        % select some predetermined fraction of hard points
        [~, ord]=sort(likelihoods, 'ascend');
        hardInd = ord(1:params.hardfrac*length(params.testData{testSetNo}));
      elseif strcmpi(params.HARD_method{testSetNo}, 'LibLinear')
        % % Test using predictability with a linear SVM classifier
        if ~isdeployed, addpath(genpath('R2011a/third-party/SVMs/liblinear-1.93/')); end
        Extrapolator=liblin_train(params.trainData.Y(:,params.targetCol), sparse([params.trainData.Y(:,setdiff(1:params.numAttr, params.targetCol)) params.trainData.Z]), params.HARD_train_args{testSetNo});  
        [pred, dummy]=liblin_predict(params.testData{testSetNo}.Y(:,params.targetCol), sparse([params.testData{testSetNo}.Y(:,setdiff(1:params.numAttr, params.targetCol)) params.testData{testSetNo}.Z]), Extrapolator, params.HARD_predict_args{testSetNo}); 
        hardInd=(pred~=params.testData{testSetNo}.Y(:, params.targetCol)); % select indices that could not be predicted using other attributes
      elseif strcmpi(params.HARD_method{testSetNo}, 'LibLinear_lim') % only using attributes that we are classifying-makes sense in one way
        % % Test using predictability with a linear SVM classifier
        if ~isdeployed, addpath(genpath('R2011a/third-party/SVMs/liblinear-1.93/')); end
        Extrapolator=liblin_train(params.trainData.Y(:,params.targetCol), sparse([params.trainData.Y(:,setdiff(1:params.numAttr, params.targetCol))]), params.HARD_train_args{testSetNo});  
        [pred, dummy]=liblin_predict(params.testData{testSetNo}.Y(:,params.targetCol), sparse([params.testData{testSetNo}.Y(:,setdiff(1:params.numAttr, params.targetCol))]), Extrapolator, params.HARD_predict_args{testSetNo}); 
        hardInd=(pred~=params.testData{testSetNo}.Y(:, params.targetCol)); % select indices that could not be predicted using other attributes
      elseif strcmpi(params.HARD_method{testSetNo}, 'ExpectedLabel')
         % Choose instances that do not match some expected labels
         hardInd = (params.testData{testSetNo}.Y(:,params.targetCol)~=params.exp_tstLabels{testSetNo}.annot(:, params.targetCol));
      end

      % Testing on hardInd
      hardData.X=params.testData{testSetNo}.X(hardInd,:);
      hardData.Y=params.testData{testSetNo}.Y(hardInd,:);
      results.hard(testSetNo)=classifyData(model, hardData, params);
      results.hardInd{testSetNo}=find(hardInd);
    end
  end
end

function res = classifyData(model, Data, params) 
% res is a structure containing 
% res.pred, res.conf
% and the evaluations
  assert(size(Data.X,2)==params.numFeat);
  if ismember(params.method, {'LibLinear', 'LibSVM'})
    switch params.method
      case 'LibLinear'
        predfoo=@liblin_predict;
        args=params.liblin_predict_args;
      case 'LibSVM'
        predfoo=@libsvm_predict;
        args=params.libsvm_predict_args;
    end
    [res.pred tmp decval]=predfoo(Data.Y(:,params.targetCol), sparse(Data.X(:,params.selFeat)), model, args); 
    %res.acc = tmp(1);
    if model.Label(1)==0 % checking the internal label assignment for the model to determine sign of the decision values
        if size(decval,2)==1
          res.conf=-decval;
        elseif size(decval,2)==2
          res.conf=decval(:,2);
        else
          abort;
        end
    else
        if size(decval,2)==1
          res.conf=decval;
        elseif size(decval,2)==2
          res.conf=decval(:,1);
        else
          abort;
        end
    end
  %elseif strcmpi(params.method, 'Metric')
  %elseif strcmpi(params.method, 'LinRegressionCoeff') || strcmpi(params.method, 'LogReg')
  %  decval=Data.X*(model.w)';% dot product of every row with the regression weight vector
  %  res.pred=(decval>0.5);
  %  res.conf=decval;
  elseif strcmpi(params.method, 'Fei') 
    decval=[Data.X ones(size(Data.X,1),1)]*(model.w)';% dot product of every row with the regression weight vector
    res.pred=(decval>model.thresh);
    res.conf=1./(1+exp(-decval));
  elseif strcmpi(params.method, 'MALSARlog') 
    decval=[Data.X ones(size(Data.X,1),1)]*(model.w)';% dot product of every row with the regression weight vector
    res.pred=(decval>model.thresh);
    res.conf=1./(1+exp(-decval));
  else
    error(sprintf('Unrecognized method %s', params.method));
  end 
  if size(Data.Y,1)>1 % need to check, especially for the hard data
    % Accuracy
    res.acc=sum(res.pred==Data.Y(:, params.targetCol))/length(res.pred)*100;
    % Fscore
    [res.Fscore res.Prec res.Rec res.TP res.TN res.FP res.FN]=Fmeasure(res.pred, Data.Y(:, params.targetCol));
    % Precision-Recall and ROC curves
    lTe=Data.Y(:,params.targetCol);
    lTe(lTe==0) = -1; % vlfeat syntax
    try 
      [res.recall, res.prec, info_pr] = vl_pr(lTe, res.conf);
    catch
      tmp=0;%dummy code for debugging
    end
    [res.tpr, res.fpr, info_roc] = vl_roc(lTe, res.conf);
    clear lTe;
    res.ap=info_pr.ap;
    if isnan(res.ap)
        warning('True labels do not have both positives and negatives');      
        res.ap=0;
    end
    res.auroc=info_roc.auc;
    %assert(isequal(res.recall, res.tpr));  
  else
    [res.acc res.Fscore res.Prec res.Rec res.TP res.TN res.FP res.FN res.recall res.prec res.recall res.tpr res.fpr res.ap res.auroc] = deal(0);
  end
end 

function params = parseArgs(varargs)
  params.valData=[];
  params.testData=[];
  params.trainData=[];
  params.hardCaseTesting=false;
  params.numFeat=0;
  params.selFeat=[];
  params.targetCol=1;
  params.method='LibLinear';
  params.liblin_predict_args = ' -q';
  params.libsvm_predict_args = ' -q';
  params.hardfrac=0.2;
  defaultHardMethod=true;
  defaultHardPredictArgs=true;
  defaultHardTrainArgs=true;
  %params.HARD_method{1} ='ExpectedLabel';
  %{'ExpectedLabel', 'KNN', 'LibLinear'};
  %params.HARD_train_args{1} = ' -s 2 -c 30 -q'; % uses an L2 SVM by default
  %params.HARD_predict_args{1} = ' -b -q'; % uses an L2 SVM by default
  params.k = 7;
  if isempty(varargs{1})
    return;
  elseif mod(size(varargs),2)~=0
    error('No of arguments must be even');
  end  
  for i=1:2:length(varargs)
    switch varargs{i}
      case 'valData'
        params.valData = varargs{i+1};
        assert(iscell(params.valData));
        if ~isempty(params.valData{1})
          params.numFeat=size(params.valData{1}.X,2);
          params.numAttr=size(params.valData{1}.Y,2);
        end
      case 'testData'
        params.testData = varargs{i+1};
        assert(iscell(params.testData));
        if ~isempty(params.testData{1})
          params.numFeat=size(params.testData{1}.X,2);
          params.numAttr=size(params.testData{1}.Y,2);
        end 
      case 'trainData'
        params.trainData = varargs{i+1};
        if ~isempty(params.trainData)
          params.numFeat=size(params.trainData.X,2);
          params.numAttr=size(params.trainData.Y,2);
        end 
      case 'method'
        params.method = varargs{i+1};
      case 'classifierArgs'
        params.classifierArgs = varargs{i+1};
      case 'selFeat'
        %params.selFeat = []; %abort-bug?
        params.selFeat = varargs{i+1}; %abort-bug?
      case 'targetCol'
        params.targetCol=varargs{i+1};
      case 'hard'
        params.hardCaseTesting=varargs{i+1};
      case 'hardmethod'
        defaultHardMethod=false;
        params.HARD_method=varargs{i+1};
        if ~iscell(params.HARD_method)
            params.HARD_method={params.HARD_method};
        end
      case 'hardtrain_args'
        defaultHardTrainArgs=false;
        params.HARD_train_args=varargs{i+1};
        if ~iscell(params.HARD_train_args)
            params.HARD_train_args={params.HARD_train_args};
        end
      case 'hardpredict_args'
        defaultHardPredictArgs=false;
        params.HARD_predict_args=varargs{i+1};
        if ~iscell(params.HARD_predict_args)
            params.HARD_predict_args={params.HARD_predict_args};
        end
      case 'liblin_predict_args'
        params.liblin_predict_args=varargs{i+1};
      case 'libsvm_predict_args'
        params.libsvm_predict_args=varargs{i+1};
      case 'k'
        params.k = varargs{i+1};
      case 'exp_tstLabels'
        params.exp_tstLabels=varargs{i+1}; 
        if ~iscell(params.exp_tstLabels)
            params.exp_tstLabels={params.exp_tstLabels};
        end
      otherwise
        error(sprintf('Unrecognized argument %s \n', varargs{i}));
    end
  end
  if isempty(params.selFeat)
    params.selFeat = ones(params.numFeat,1);
  end
  numTestSets=length(params.testData);
  if defaultHardMethod
    params.HARD_method=repmat({'LibLinear'}, length(params.testData), 1); 
  end 
  if defaultHardPredictArgs
    for i=1:length(params.HARD_method)
      switch params.HARD_method{i}
        case {'LibLinear','LibLinear_lim'}
          params.HARD_predict_args{i} = ' -b -q'; % uses an L2 SVM by default
        otherwise
          % no args required
      end
    end
  end
  if defaultHardTrainArgs
    for i=1:length(params.HARD_method)
      switch params.HARD_method{i}
        case {'LibLinear', 'LibLinear_lim'}
          params.HARD_train_args{i} = ' -s 2 -c 30 -q'; % uses an L2 SVM by default
        otherwise
          % no args required          
      end
    end
  end 
end  

