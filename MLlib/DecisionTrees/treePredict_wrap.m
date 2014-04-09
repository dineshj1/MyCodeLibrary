function [pred, dummy, decval]=treePredict_wrap(dummy, X, tree, args)
  dummy=[];
  [pred, decval]=predict(tree, X); % TODO add possibility of using args (for pruned trees) 

  % truncate decval based on ordering of classes
  posClsInd=find(tree.ClassNames==1);
  decval=decval(:,posClsInd);
end
