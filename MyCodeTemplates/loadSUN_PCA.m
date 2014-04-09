function [features, attributematrix, attributes, attributecategories, trainingInd, valInd, testingInd, categories, classes, classNames, class_attrib_mat, feature_channels, unused_attributematrix] = loadSUN_PCA(varargin)  

  params=parseArgs(varargin);
  %% instances
  mainDataFolder = '/scratch/vision/dineshj/Attribute_datasets/SUNattr/';
  attrAnnotFolder = [mainDataFolder '/SUNAttributeDB/'];
  splitFolder = [attrAnnotFolder '/splits/splits_same'];

  tmp=load([attrAnnotFolder '/jd_sceneAnnot.mat']); % precomputed
  classes=tmp.classes;  classNames=tmp.classNames;
  clear('tmp');
  
  if ~params.PCA
    tmp=load([attrAnnotFolder '/jd_features.mat']);
    features=tmp.features;
    feature_channels=tmp.feature_channels; 
  else
    tmp=load([attrAnnotFolder '/jd_PCAfeatures.mat']);
    features=tmp.PCAfeatures;
    feature_channels=tmp.feature_channels; 
  end
  clear('tmp');

  %% attributes, attributecategories
  load([attrAnnotFolder '/attributes.mat']);
  attribnames=attributes; clear('attributes');
  params.categories=(1:length(attribnames))'; % dummy - not needed at this point
  assert(length(params.categories) == length(attribnames));
  attributes = struct('name', attribnames, 'category', num2cell(params.categories)); % 0 denotes no grouping 

  attributecategories=[]; % dummy - not needed at this point
  
  %% attribute matrix and image classes
  % values
  load([attrAnnotFolder '/attributeLabels_continuous.mat']); % labels_cv now contains the image-attribute matrix
  attributematrix=labels_cv; clear labels_cv; 
  % threshold every column of attribute matrix
  for i=1:size(attributematrix, 2)
    tmp=attributematrix(:,i); 
    thresh=0.5*mean(tmp(tmp>0));
    attributematrix(:,i)=(tmp>=thresh);
  end  
  
  assert(length(attributes) == size(attributematrix,2));
  clsNames=unique(classes);
  numClasses = length(clsNames);
  for i=1:numClasses
    currCls=clsNames(i);
    currClsInd=find(classes==i);
    currMat=attributematrix(currClsInd,:);
    class_attrib_mat.mean(i,:)=mean(currMat);
    class_attrib_mat.clauses{i}=mean(currMat);
    class_attrib_mat.std(i,:)=std(currMat);
  end

  % splits 
  if params.split<=10 % one of the 10 specified splits
    tmp=load([splitFolder '/jd_traintestSplits.mat']);
    trainingInd=tmp.trainingInd(:,params.split);
    testingInd=tmp.testingInd(:,params.split);
    valInd=[]; % abort - undefined for now
    if params.allTrain
      trainingInd=abort;
    end
  elseif params.split==99 % stands for repeatable random split
    trainFrac=0.4;
    testFrac=0.4;
    numSamples=size(features,1);

    rng(250285);
    ord=randperm(numSamples);
    rng('shuffle');

    numTrain=ceil(trainFrac*numSamples);
    numTest=ceil(testFrac*numSamples);
    numVal=numSamples-numTrain-numTest;

    trainingInd=ord(1:numTrain);
    testingInd{1}=ord(numTrain+(1:numTest));
    valInd{1}=ord(numTrain+numTest+(1:numVal));
  elseif params.split==100 % stands for non-repeatable random split
    trainFrac=0.4;
    testFrac=0.4;
    numSamples=size(features,1);

    rng('shuffle');
    ord=randperm(numSamples);
    rng('shuffle');

    numTrain=ceil(trainFrac*numSamples);
    numTest=ceil(testFrac*numSamples);
    numVal=numSamples-numTrain-numTest;

    trainingInd=ord(1:numTrain);
    testingInd{1}=ord(numTrain+(1:numTest));
    valInd{1}=ord(numTrain+numTest+(1:numVal));
  else
    error('No such split defined');
  end

  unused_attributematrix=[];
  %categories= params.categories;  
  %if params.truncate
  %  reqdAttribs = [attributecategories.attributes];
  %  tmp=attributematrix;
  %  attributematrix = tmp(:,reqdAttribs);
  %  class_attrib_mat.mean=class_attrib_mat.mean(:, reqdAttribs);
  %  class_attrib_mat.std=class_attrib_mat.std(:, reqdAttribs);
  %  class_attrib_mat.annot=class_attrib_mat.annot(:, reqdAttribs);

  %  unused_attributematrix = tmp(:, setdiff(1:length(attributes),reqdAttribs));
  %  clear tmp;
  %  attributes=attributes(reqdAttribs);
  %  categories=categories(reqdAttribs);
  %  count =0;
  %  for i=1:length(attributecategories)
  %    numAttr=length(attributecategories(i).attributes);
  %    attributecategories(i).attributes=count+1:count+length(attributecategories(i).attributes);
  %    count = count+length(attributecategories(i).attributes);
  %    assert(length(attributecategories(i).attributes)==numAttr);
  %  end
  %else
  %  unused_attributematrix=[];
  %end  
  features=full(double(features)); 
  attributematrix=double(attributematrix);
  classes=double(classes);
  categories=params.categories;
end

 
function [param] = parseArgs(args)
  param.split=99;
  param.attriblist=2;
  param.defaultCategory=true;
  param.truncate=true;
  param.PCA=true;
  param.allTrain=false;
  numarg = length(args);
  if (numarg > 2)
    for i=1:2:numarg
      switch args{i}
        case 'split'
          param.split = args{i+1};
        case 'attriblist'
          param.attriblist= args{i+1};
        case 'categories'  % dummy at this point. Not being used.
          param.defaultCategory=false;
          param.categories= args{i+1};
        case 'truncate'
          param.truncate=args{i+1};
        case 'PCA'
          param.PCA=args{i+1};
        case 'allTrain'
          param.allTrain=args{i+1};
        otherwise
          error(sprintf('invalid parameter name %s', args{i}));
      end
    end
  end
  %if param.defaultCategory
  %  if param.attriblist ==1
  %    param.categories = zeros(85,1);
  %    param.categories(1:8) = 1; %color
  %    param.categories(9:14) = 2; %texture
  %    param.categories(15:18) = 3; % shape
  %    param.categories([19:33 45 46]) = 4; % parts
  %    param.categories(35:44) = 5; % activities
  %    param.categories(47:51) = 6; % behavior
  %    param.categories(52:62) = 7; % nutrition
  %    param.categories(66:78) = 8; % habitat
  %    param.categories(79:85) = 9; % character
  % elseif param.attriblist ==2
  %    param.categories = zeros(85,1);
  %    param.categories(1:8) = 1; %color
  %    param.categories(9:14) = 2; %texture
  %    param.categories(15:18) = 3; % shape
  %    param.categories([19:33 45 46]) = 4; % parts
  %    param.categories(34:44) = 5; % activities
  %    param.categories(47:51) = 6; % behavior
  %    param.categories(52:62) = 7; % nutrition
  %    param.categories(63:78) = 8; % habitat
  %    param.categories(79:85) = 9; % character
  % else
  %    error('No such attribute list known');
  %  end
  %end
end  
