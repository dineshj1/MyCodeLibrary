function checkParamsMatch(matfilename,params)
  paramNames=fieldnames(params.List);
  origParams=params;
  load(matfilename,'params');
  for i = 1:length(paramNames)
    currParamName=paramNames{i};
    assert(eval(sprintf('isequal(params.%s,origParams.%s)',currParamName,currParamName)),...
      sprintf('%s does not match', paramNames{i}));
  end
end
