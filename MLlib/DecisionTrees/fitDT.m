function [DT, DNF]=fitDT(Data, attributes, responseName, draw)%, testData, curr_Concept)
  % fits a decision tree DT to given data with binary labels and expresses the positive class as a DNF function of the rest of the variables
  predNames={attributes.name}';
  if nargin<2
    predNames=cellstr(num2str([1:size(Data.X,2)]'));
  end
  if nargin<3
    responseName='output';
  end
  if nargin<4
    draw=false;
  end
  
  fitFnName=@ClassificationTree.fit; % might need be changed to fitctree in future Matlab releases

%leafs=[1,5,10,20];
%rng('default')
  
 % selLeafs=40;

%if draw
%N = numel(leafs);
%err = zeros(N,1);
%valFrac=0.3;
%numSamples=size(Data.X,1);
%rng(2351235);
%tmp=randperm(valFrac);
%rng('shuffle');
%trainFrac=1-valFrac;
%trainInd=tmp(1:floor(trainFrac*numSamples));
%valInd=setdiff(1:numSamples, trainInd);
%trainData.X=Data.X(trainInd,:);
%trainData.Y=Data.Y(trainInd,:);
%valData.X=Data.X(valInd,:);
%valData.Y=Data.Y(valInd,:); 

%for n=1:N  
%  tree{n}=fitFnName(Data.X, Data.Y, 'PredictorNames', predNames, 'ResponseName', responseName, 'MinLeaf', leafs(n));    
%  res(n) = classifyData(tree{n}, testData, curr_Concept, @treePredict_wrap); 
%end
% if draw
% figure, 
% subplot(3,1,1), plot(leafs,[res.Fscore]); ylabel('val Fscore');
% subplot(3,1,2), plot(leafs,[res.ap]); ylabel('val AP');
% subplot(3,1,3), plot(leafs,[res.ap_old]); ylabel('val AP(old)');
% %hold on, plot(leafs,[res.ap_old], '--');
% xlabel('Min Leaf Size');
% ylabel('val AP');
% 
% % figure, plot(leafs,[res.auroc]);
% % hold on, plot(leafs,[res.auroc_old], '--');
% % xlabel('Min Leaf Size');
% % ylabel('val AUC');
% end 
% [~,best]=max([res.ap]);
% selLeafs=leafs(best);
% DT=tree{best};
%else 
%
%%TODO cross-validation as usual won't work because loss function is
%%accuracy. Should measure AP or Fscore because of imbalance in data. See
%%kFoldLoss>"write your own loss function"
%
% %N = numel(leafs);
% %err = zeros(N,1);
% %for n=1:N
% %  t=fitFnName(Data.X, Data.Y, 'PredictorNames', predNames, 'ResponseName', responseName, 'CrossVal', 'On', 'kfold', 5, 'MinLeaf', leafs(n));    
% %  err(n) = kfoldLoss(t);
% %end
% %plot(leafs,err);
% %xlabel('Min Leaf Size');
% %ylabel('cross-validated error');
% %
% %selLeafs=leafs((err==min(err)));
% %selLeafs=selLeafs(end);
%
%DT=fitFnName(Data.X, Data.Y, 'PredictorNames', predNames, 'ResponseName', responseName, 'MinLeaf', selLeafs);    
%end

leafsz=1;
DT=fitFnName(Data.X, Data.Y, 'PredictorNames', predNames, 'ResponseName', responseName, 'MinLeaf', leafsz, 'MinParent', 1);    
%DT=fitFnName(Data.X, Data.Y, 'PredictorNames', predNames, 'ResponseName', responseName);   
    if draw
      % treedisp in graph mode
      view(DT, 'mode', 'graph');
    end
  
  %TODO: how to compute DNF?
  DNF=[];
end
