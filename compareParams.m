function [param1, param2]=compareParams(matfile1, matfile2)
  % displays and returns parameters for the two cases
  
  load(matfile1, 'params');
  param1=params; clear params;
  load(matfile2, 'params');
  param2=params; clear params;

  % display param1, param2
  disp(param1); disp(param2);

  % display differing fields
  makeLine('Fields in which these params differ:\n');
  fields=fieldnames(param1);
  for i=1:length(fields)
    try
      if ~isequal(getfield(param1, fields{i}), getfield(param2, fields{i}))
        fprintf('%s\n',fields{i});
      end
    catch err
      getReport(err)
      pause
    end
  end
end
