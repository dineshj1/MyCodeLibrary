function res = classifyData(model, Data, targetCol, predfoo) 
  % res is a binClassRes instance
  res=binClassRes;
  if nargin<4
    predfoo=@liblin_predict_wrap; % other predfoos must also have the same interface as liblin_predict to be compatible
  end

  % making inputFormat argument unnecessary (because we can just look at the function itself) - to remove once we have corrected all calling instances (mainly in stagedLearning.m)
  args=[];
  [res.pred, ~, res.conf]=predfoo(Data.Y(:,targetCol), Data.X, model, args); 
  

  if size(Data.Y,1)>1 % need to check, especially for the hard data
    % Accuracy
    res.acc=sum(res.pred==Data.Y(:,targetCol))/length(res.pred)*100;
    % Fscore
    [res.Fscore res.Prec res.Rec res.TP res.TN res.FP res.FN]=Fmeasure(res.pred, Data.Y(:,targetCol));
    % Precision-Recall and ROC curves
    lTe=Data.Y(:,targetCol);

%% outdated code reintroduced for the sake of comparison    
%lTe(lTe==0) = -1; % vlfeat syntax
%[res.reca_old, res.prec_old, info_pr] = vl_pr(lTe, res.conf);
%res.ap_old=info_pr.ap;
%[res.tpr_old, res.tnr_old, info_roc] = vl_roc(lTe, res.conf);
%res.auroc_old=info_roc.auc;
   
    try
      [res.misc.reca, res.misc.prec,~,res.AP]=perfcurve(lTe,res.conf,1, 'xCrit', 'reca', 'yCrit', 'prec');
      [res.misc.fpr,res.misc.tpr,~,res.AUC]=perfcurve(lTe,res.conf,1, 'xCrit', 'FPR', 'yCrit', 'TPR');
    catch err
      getReport(err)
      if length(unique(lTe))<2
        [res.misc.reca, res.misc.prec, res.misc.fpr,res.misc.tpr]=deal(0);
        res.AP=0.5;
        res.AUC=0.5;
        clear lTe;    
      else
        fprintf('Unknown error!');  
        abort
      end
    end
  else      
    [res.acc res.Fscore res.Prec res.Rec res.TP res.TN res.FP res.FN res.misc.reca res.misc.prec res.misc.fpr res.misc.tpr res.AP res.AUC] = deal(0);
  end
end 
 
