function res = classifyData(model, Data, targetCol) 
% res is a structure containing 
% res.pred, res.conf
% and the evaluations
    predfoo=@liblin_predict;
    args=' -q';
    [res.pred tmp decval]=predfoo(Data.Y(:,targetCol), sparse(Data.X), model, args); 
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
   if size(Data.Y,1)>1 % need to check, especially for the hard data
    % Accuracy
    res.acc=sum(res.pred==Data.Y(:,targetCol))/length(res.pred)*100;
    % Fscore
    [res.Fscore res.Prec res.Rec res.TP res.TN res.FP res.FN]=Fmeasure(res.pred, Data.Y(:,targetCol));
    % Precision-Recall and ROC curves
    lTe=Data.Y(:,targetCol);
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
 
