function [Yhard, dummy, Ysoft] = forestTest_wrap(dummyY, X, model, dummyOpts)
  % casts forestTest into the predFoo interface required by classifyData
  dummy=0;
  [Yhard, Ysoft] = forestTest(model, X, dummyOpts);

  posClsInd=find(model.treeModels{1}.classes==1);
  Ysoft=Ysoft(:,posClsInd);  
end  
