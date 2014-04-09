function displayFloats(varNames, separator)
  if nargin<2
    separator='\n'
  end
  for i=1:length(varNames)
    try
      fprintf('%s:%f%c' varNames{i}, eval(varNames{i}),separator);
    catch err
      fprintf('%s:<INV>%c' varNames{i}, separator);
    end
  end
  fprintf('\n');
end 
