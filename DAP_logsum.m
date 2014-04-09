function [MAP_classPred,res,overall_acc,Confusion] = DAP_logsum(testData, class_attrib_mat, mean_attrib_presence, clsPrior)
  % testData should have these components - attributes (predicted probability of presence) and classes
  % class_attrib_mat has the binary attribute value of each attribute for each class(attribute signatures)
  % mean_attrib_presence is a vector containing the average presence of each attributes 
  % clsPrior is a vector specifying the probability of presence of various classes
  numClasses=size(class_attrib_mat,1);
  if nargin<4
    clsPrior=ones(1,numClasses)/numClasses;
  end
  assert(all(clsPrior>=0), 'class prior distribution may not be negative');
  clsPrior=clsPrior/sum(clsPrior);

  %% computing class likelihoods
  assert(all(testData.attributes(:)>=0),'Confidence scores (probabilities) must be >=0');
  assert(all(testData.attributes(:)<=1), 'Confidence scores (probabilities) must be <=1');
  logprob1=log(max(testData.attributes,eps));
  logprob0=log(max(1-testData.attributes,eps));
  for classnum=1:numClasses
    signature=class_attrib_mat(classnum, :);
    log_numerator=sum(logprob1(:,signature==1),2)+sum(logprob0(:,signature==0),2);
    log_denominator(classnum)=sum(log(mean_attrib_presence(signature==1)+eps))+sum(log(1-mean_attrib_presence(signature==0)+eps));
    log_class_likelihood(:, classnum)=log_numerator-log_denominator(classnum);
  end

  log_clsPrior=log(clsPrior);
  testingClasses=unique(testData.class);
  numSamples=length(testData.class);
  log_class_likelihood=log_class_likelihood(:,testingClasses)+log_clsPrior(ones(numSamples,1),testingClasses); % restricting to only the testing classes
  [~,MAP_classPred]=max(log_class_likelihood,[],2);
  MAP_classPred=testingClasses(MAP_classPred);
  
  totalLikelihood=repmat(sum(exp(log_class_likelihood),2),1,size(log_class_likelihood,2));
  % per-class confidence scores
  Confidence=exp(log_class_likelihood)./totalLikelihood;

  %% Evaluation of class predictions
  overall_acc=(sum(MAP_classPred==testData.class)/length(MAP_classPred))*100;
  [confmat,order]=confusionmat(testData.class,MAP_classPred);
  %confmat(i,j) is a count of observations known to be in group i but predicted to be in group j.
  
  % %normalize columns 
  % Confusion.mat=confmat./repmat(sum(confmat,1),size(confmat,1),1);
  %normalize rows
  Confusion.mat=confmat./repmat(sum(confmat,2),1,size(confmat,1));
  Confusion.order=order;

  % Class-wise AP performance
  for i=1:length(testingClasses)
    res(i).classnum = testingClasses(i);
    res(i).acc=(sum((MAP_classPred==testingClasses(i))==(testData.class==testingClasses(i)))/length(MAP_classPred))*100;
    [res(i).Fscore, res(i).Prec, res(i).Rec, res(i).TP, res(i).TN, res(i).FP, res(i).FN]=Fmeasure(MAP_classPred==testingClasses(i), testData.class==testingClasses(i));

    %conf=class_likelihood(:,testingClasses(i))./totalLikelihood;
    %% Precision-Recall and ROC curves
    [res(i).recall, res(i).prec, ~, res(i).ap]=perfcurve(testData.class,Confidence(:,i),testingClasses(i),'xCrit','reca','yCrit','prec');

    skew=sum(testData.class==testingClasses(i))/length(testData.class);
    res(i).min_ap=1+(1-skew)*log(1-skew)/skew;
    res(i).rand_ap=skew;
    res(i).norm_ap=(res(i).ap-res(i).min_ap)./(res(i).rand_ap-res(i).min_ap);
    
    [res(i).fpr, res(i).tpr, ~, res(i).auroc]=perfcurve(testData.class,Confidence(:,i),testingClasses(i),'xCrit','FPR','yCrit','TPR');
  end
end
