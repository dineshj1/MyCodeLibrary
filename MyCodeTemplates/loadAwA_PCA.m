function [features, attributematrix, attributes, attributecategories, trainingInd, valInd, testingInd, categories, classes, classnames, class_attrib_mat, feature_channels, unused_attributematrix] = loadAwA_PCA(varargin)  
  params=parseArgs(varargin);
  %% instances
  datafolder = '/scratch/vision/dineshj/Attribute_datasets/Animals_with_attributes/Animals_with_Attributes';
  if params.PCA
    load ('/scratch/vision/dineshj/Semantic_attributes/codes/Matfiles/AwA_PCA290_new.mat');    
  else
    load (['/scratch/vision/dineshj/Semantic_attributes/codes/Matfiles/AwA_data.mat'], 'instances', 'classes');
    features=instances;
    clear('instances');
    load ('Matfiles/AwA_PCA290_new.mat', 'feature_channels');        
    %load ('Matfiles/AwA_PCA290_new.mat', 'feature_channels');        
  end
  %load('/scratch/vision/dineshj/Semantic_attributes/codes/Matfiles/AwA_PCA_420.mat', 'features', 'featureTypes');
  %% attributes, categories
  FID = fopen([datafolder '/predicates.txt'], 'r');
  temp = textscan(FID, '%*d%s'); attribnames = temp{1};
  fclose(FID);
  assert(length(params.categories) == length(attribnames));
  attributes = struct('name', attribnames, 'category', num2cell(params.categories)); % 0 denotes no grouping 
  attributecategories=[];
  %temp = max([attributes.category]);
  %for groupNo=1:temp
  %    attributecategories(groupNo).attributes = find([attributes.category]==groupNo);
  %    attributecategories(groupNo).support = [];
  %end
  
  %attributecategories(1).name = 'shape'; %attributecategories(1).support = 71:422;
  %attributecategories(2).name = 'textures'; %attributecategories(2).support = [1:70 423:434];
  %% attribute matrix and image classes
  % values
  %load (['/scratch/vision/dineshj/Semantic_attributes/codes/Matfiles/AwA_data.mat'], 'classes', 'featureTypes');
  %load (['/scratch/vision/dineshj/Semantic_attributes/codes/Matfiles/AwA_data.mat'], 'classes');
  attribs = [];
  %classes = [];
  load([datafolder '/predicate-matrix-binary.txt']); % predicate_matrix_binary now contains the animal-attribute associations
  load([datafolder '/predicate-matrix-continuous.txt']); % predicate_matrix_binary now contains the animal-attribute associations
  predicate_matrix_continuous=max(predicate_matrix_continuous, 0);% making sure this is positive (to handle the -1's in the matrix)

    attributematrix = false(size(features,1), length(attributes));
    assert(length(attributes) == size(predicate_matrix_binary,2));
    numAnimals = length(unique(classes));
    assert(numAnimals == size(predicate_matrix_binary,1));
    for i=1:numAnimals
        ind = find(classes==i);
        attributematrix(ind, :) = predicate_matrix_binary(i*ones(length(ind),1),:);
    end
    
%   for i=1:6
%     feature_channels(i).ll=50*(i-1)+1;
%     feature_channels(i).ul=50*i;
%     feature_channels(i).sz=50;
%     feature_channels(i).typeName=featureTypes(i).name;
%   end
  
  class_attrib_mat.mean=predicate_matrix_continuous;
  class_attrib_mat.std=zeros(size(class_attrib_mat.mean,1),size(class_attrib_mat.mean,2));
  class_attrib_mat.annot=predicate_matrix_binary; % thresholded (comes with the dataset) 

  FID = fopen([datafolder '/classes.txt'], 'r');
  temp = textscan(FID, '%*d%s'); classnames = temp{1}; 
  fclose(FID);
  

  if params.mergeClasses
    % pick tuples of classes to merge into artificial superclasses
    rng(2412141); % for repeatability
    ord=randperm(numAnimals); 
    rng('shuffle');
    count_cl=0;
    count_supcl=0;
    tupleSize=params.mergeClasses; 
    superClassLabels=NaN(length(classes),1);
    while count_cl<numAnimals
      endClass=min(numAnimals, count_cl+tupleSize);
      currClasses=ord(count_cl+1:endClass);
      count_supcl=count_supcl+1;
      superClass(count_supcl).classes=currClasses;
      count_cl=endClass;
      
      % modify variable class_attrib_mat for the superclasses
      superClass_attrib_mat.mean(count_supcl,:)=mean(class_attrib_mat.mean(currClasses,:),1);

      % set DNF formulae for the superclasses (for the moment, represent simply by listing each conjunctive clause)
      superClass_attrib_mat.clauses{count_supcl,1}=class_attrib_mat.annot(currClasses,:);

      % modify variable classes to represent the superclasses (superClassLabels)
      ind=find(ismember(classes, currClasses));  
      superClassLabels(ind)=count_supcl;

      % modify variable classnames for the superclasses
      tmp=classnames(currClasses);
      superClassNames{count_supcl}=strcat(tmp{:});
    end

    class_attrib_mat=superClass_attrib_mat;
    classes=superClassLabels;
    classnames=superClassNames;
  else
    class_attrib_mat.clauses=mat2cell(predicate_matrix_binary, ones(numAnimals,1));
  end

 
  if params.split==1 % the original split (all data)
    FID = fopen([datafolder '/trainclasses.txt'], 'r');
    temp = textscan(FID, '%s'); trainclassnames = temp{1};
    fclose(FID);
    FID = fopen([datafolder '/testclasses.txt'], 'r');
    temp = textscan(FID, '%s'); testclassnames = temp{1};
    fclose(FID);        
    
    %valFrac=0.2;
    train_classno = find(ismember(classnames, trainclassnames)); 
    test_classno = find(ismember(classnames, testclassnames)); 
    
    allTrainClsInd = find(ismember(classes, train_classno));
    testingInd1 = find(ismember(classes, test_classno));

    numAttrib=length(attributes);
    trainingInd=repmat({allTrainClsInd},1,numAttrib);
    testingInd=repmat({testingInd1},1,numAttrib);
    valInd=[];

    % separating unseen data into testing and validation data
    %% first test set (different classes)
    %rng(1212341);
    %temp=randperm(length(testingInd1));
    %rng('shuffle');
    %valInd{1} = testingInd1(temp(1:ceil(valFrac*length(temp))));
    %testingInd{1} = setdiff(testingInd1, valInd{1});  

    % separating training ind into training, validation and test sets
    %rng(4621451);
    %tmp=randperm(length(allTrainClsInd));
    %rng('shuffle');
    %trainingInd=allTrainClsInd(tmp(1:0.6*length(allTrainClsInd)));
    
    %% second test set (same classes)
    %testingInd1=setdiff(allTrainClsInd, trainingInd);
    %rng(3213419);
    %temp=randperm(length(testingInd1));
    %rng('shuffle');
    %valInd{2} = testingInd1(temp(1:ceil(valFrac*length(temp))));
    %testingInd{2} = setdiff(testingInd1, valInd{2}); 

    %if params.allTrain
    %  trainingInd=allTrainClsInd;
    %end
  elseif params.split==3 % possibly reduced, attribute-specific training data from all classes (not segregated into training and testing classes)
    numAttrib=length(attributes);
    testingInd{numAttrib}=[];
    trainingInd{numAttrib}=[];
    valInd{numAttrib}=[];
    for i=1:numAttrib
      positives=find(attributematrix(:,i));
      negatives=find(~attributematrix(:,i));
      assert(~isempty(positives) && ~isempty(negatives),'There must be at least one each of positives and negatives!');

      rng(141214+i);
      pos_ord=positives(randperm(length(positives)));
      rng('shuffle');
      rng(141214+i);
      neg_ord=negatives(randperm(length(negatives)));
      rng('shuffle'); 

      if params.allTrain==1 % in the context of this split, means not wasting any data between training and testing data
        req_numPos=floor(length(positives)/2);
        req_numNeg=floor(length(negatives)/2);
      else % limiting the amount of data
        if params.allTrain==0
          req_numPos=25; req_numNeg=500;
        elseif params.allTrain==-1
          req_numPos=15; req_numNeg=100;
        end
        if length(positives)<2*req_numPos
          req_numPos=floor(length(positives)/2);
        end
        if length(negatives)<2*req_numNeg
          req_numNeg=floor(length(negatives)/2);
        end         
      end
      trainingInd{i}=[pos_ord(1:req_numPos); neg_ord(1:req_numNeg)];
      testingInd{i}=[pos_ord(req_numPos+(1:req_numPos));     neg_ord(req_numNeg+(1:req_numNeg))]; 
    end
    
  else
    error('No such split defined');
  end
  trainingInd=trainingInd;
  tmp{2}=testingInd; tmp{1}=[];
  testingInd=tmp;
  tmp{2}=valInd; tmp{1}=[];              
  valInd=tmp;

  categories=[];
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

  % making corrections to produce testing, training inds etc. in the same format as loadSUN_PCA (one set for each concept)
  if params.sameClass
    testingInd=testingInd{2};
    valInd=valInd{2};
  else
    testingInd=testingInd{1};
    valInd=valInd{1};
  end

  % replicate trainingInd, testing and valInd so that each concept is allotted one cell
  if ~iscell(trainingInd)
    trainingInd=repmat({trainingInd}, size(attributematrix, 2), 1);
    testingInd=repmat({testingInd}, size(attributematrix, 2), 1);
    valInd=repmat({valInd}, size(attributematrix,2), 1);
  end

  % final reformatting
  features=full(double(features)); 
  attributematrix=double(attributematrix);
  classes=double(classes);
end

 
function [param] = parseArgs(args)
  param.split=1;
  param.attriblist=2;
  param.defaultCategory=true;
  param.truncate=true;
  param.PCA=true;
  param.allTrain=0;
  param.sameClass=true;
  param.mergeClasses=false;
  numarg = length(args);
  if (numarg > 2)
    for i=1:2:numarg
      switch args{i}
        case 'split'
          param.split = args{i+1};
        case 'attriblist'
          param.attriblist= args{i+1};
        case 'categories'
          param.defaultCategory=false;
          param.categories= args{i+1};
        case 'truncate'
          param.truncate=args{i+1};
        case 'PCA'
          param.PCA=args{i+1};
        case 'allTrain'
          param.allTrain=args{i+1};
        case 'sameClass'
          param.sameClass=args{i+1};
        case 'mergeClasses'  % controls whether classes are artifically merged or not. Must also return DNFs
          param.mergeClasses=args{i+1};
        otherwise
          error(sprintf('invalid parameter name %s', args{i}));
      end
    end
  end
  if param.defaultCategory
    if param.attriblist ==1
      param.categories = zeros(85,1);
      param.categories(1:8) = 1; %color
      param.categories(9:14) = 2; %texture
      param.categories(15:18) = 3; % shape
      param.categories([19:33 45 46]) = 4; % parts
      param.categories(35:44) = 5; % activities
      param.categories(47:51) = 6; % behavior
      param.categories(52:62) = 7; % nutrition
      param.categories(66:78) = 8; % habitat
      param.categories(79:85) = 9; % character
    elseif param.attriblist ==2
      param.categories = zeros(85,1);
      param.categories(1:8) = 1; %color
      param.categories(9:14) = 2; %texture
      param.categories(15:18) = 3; % shape
      param.categories([19:33 45 46]) = 4; % parts
      param.categories(34:44) = 5; % activities
      param.categories(47:51) = 6; % behavior
      param.categories(52:62) = 7; % nutrition
      param.categories(63:78) = 8; % habitat
      param.categories(79:85) = 9; % character
    else
      error('No such attribute list known');
    end
  end
end  
