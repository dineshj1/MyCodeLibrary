function [features, attributematrix, attributes, attributecategories, trainingInd, valInd, testingInd, categories, classes, classnames, class_attrib_mat, feature_channels, unused_attributematrix] = loadAwA_PCA(varargin)  
  params=parseArgs(varargin);
  %% instances
  datafolder = '/scratch/vision/dineshj/Attribute_datasets/Animals_with_attributes/Animals_with_Attributes';
  if params.PCA
    %load ([datafolder '/Features/reduced_feat.mat']);
    %features = x';
    %load('/scratch/vision/dineshj/Semantic_attributes/codes/Matfiles/AwA_PCA290_new.mat', 'feature_channels', 'classes');
    
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
  temp = max([attributes.category]);
  for groupNo=1:temp
      attributecategories(groupNo).attributes = find([attributes.category]==groupNo);
      attributecategories(groupNo).support = [];
  end
  %attributecategories(1).name = 'shape'; %attributecategories(1).support = 71:422;
  %attributecategories(2).name = 'textures'; %attributecategories(2).support = [1:70 423:434];
  %% attribute matrix and image classes
  % values
  %load (['/scratch/vision/dineshj/Semantic_attributes/codes/Matfiles/AwA_data.mat'], 'classes', 'featureTypes');
  %load (['/scratch/vision/dineshj/Semantic_attributes/codes/Matfiles/AwA_data.mat'], 'classes');
  attribs = [];
  %classes = [];
  load([datafolder '/predicate-matrix-binary.txt']); % predicate_matrix_binary now contains the animal-attribute associations
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
  
  class_attrib_mat.mean=predicate_matrix_binary;
  class_attrib_mat.std=zeros(size(class_attrib_mat.mean,1),size(class_attrib_mat.mean,2));
  class_attrib_mat.annot=class_attrib_mat.mean;

  FID = fopen([datafolder '/classes.txt'], 'r');
  temp = textscan(FID, '%*d%s'); classnames = temp{1}; 
  fclose(FID);
  
  if params.split==1 % the original split
    FID = fopen([datafolder '/trainclasses.txt'], 'r');
    temp = textscan(FID, '%s'); trainclassnames = temp{1};
    fclose(FID);
    FID = fopen([datafolder '/testclasses.txt'], 'r');
    temp = textscan(FID, '%s'); testclassnames = temp{1};
    fclose(FID);        
    
    valFrac=0.2;
    train_classno = find(ismember(classnames, trainclassnames)); 
    test_classno = find(ismember(classnames, testclassnames)); 
    
    allTrainClsInd = find(ismember(classes, train_classno));
    testingInd1 = find(ismember(classes, test_classno));
    rng(4621451);
    tmp=randperm(length(allTrainClsInd));
    rng('shuffle');
    trainingInd=allTrainClsInd(tmp(1:0.6*length(allTrainClsInd)));
    % first test set (different classes)
    rng(1212341);
    temp=randperm(length(testingInd1));
    rng('shuffle');
    valInd{1} = testingInd1(temp(1:ceil(valFrac*length(temp))));
    testingInd{1} = setdiff(testingInd1, valInd{1});  

    % second test set (same classes)
    testingInd1=setdiff(allTrainClsInd, trainingInd);
    rng(3213419);
    temp=randperm(length(testingInd1));
    rng('shuffle');
    valInd{2} = testingInd1(temp(1:ceil(valFrac*length(temp))));
    testingInd{2} = setdiff(testingInd1, valInd{2}); 

    if params.allTrain
      trainingInd=allTrainClsInd;
    end
  elseif params.split==2 % the original split
    FID = fopen([datafolder '/trainclasses.txt'], 'r');
    temp = textscan(FID, '%s'); trainclassnames = temp{1};
    fclose(FID);
    FID = fopen([datafolder '/testclasses.txt'], 'r');
    temp = textscan(FID, '%s'); testclassnames = temp{1};
    fclose(FID);        
    
    valFrac=0.2;
    train_classno = find(ismember(classnames, trainclassnames)); 
    test_classno = find(ismember(classnames, testclassnames)); 
    
    allTrainClsInd = find(ismember(classes, train_classno));
    testingInd1 = find(ismember(classes, test_classno));
    rng(4621451);
    tmp=randperm(length(allTrainClsInd));
    rng('shuffle');
    trainingInd=allTrainClsInd(tmp(1:0.6*length(allTrainClsInd)));
    % first test set (different classes)
    rng(1212341);
    temp=randperm(length(testingInd1));
    rng('shuffle');
    valInd{1} = testingInd1(temp(1:ceil(valFrac*length(temp))));
    testingInd{1} = testingInd1; %setdiff(testingInd1, valInd{1});  

    % second test set (same classes)
    testingInd1=setdiff(allTrainClsInd, trainingInd);
    rng(3213419);
    temp=randperm(length(testingInd1));
    rng('shuffle');
    valInd{2} = testingInd1(temp(1:ceil(valFrac*length(temp))));
    testingInd{2} = setdiff(testingInd1, valInd{2}); 

    if params.allTrain
      trainingInd=allTrainClsInd;
    end
  else
    error('No such split defined');
  end

  categories= params.categories;  
  if params.truncate
    reqdAttribs = [attributecategories.attributes];
    tmp=attributematrix;
    attributematrix = tmp(:,reqdAttribs);
    class_attrib_mat.mean=class_attrib_mat.mean(:, reqdAttribs);
    class_attrib_mat.std=class_attrib_mat.std(:, reqdAttribs);
    class_attrib_mat.annot=class_attrib_mat.annot(:, reqdAttribs);

    unused_attributematrix = tmp(:, setdiff(1:length(attributes),reqdAttribs));
    clear tmp;
    attributes=attributes(reqdAttribs);
    categories=categories(reqdAttribs);
    count =0;
    for i=1:length(attributecategories)
      numAttr=length(attributecategories(i).attributes);
      attributecategories(i).attributes=count+1:count+length(attributecategories(i).attributes);
      count = count+length(attributecategories(i).attributes);
      assert(length(attributecategories(i).attributes)==numAttr);
    end
  else
    unused_attributematrix=[];
  end  
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
 param.allTrain=false;
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
