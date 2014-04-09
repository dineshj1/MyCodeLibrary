function obj=dispRes(obj,varargin)
  if isempty(varargin)
      varargin='all';
  end
  switch varargin{1}
    case 'any'
      varNames=varargin(2:end);
    case 'fixOP'
      varNames={'acc','Fscore','Prec','Rec','TP','TN','FP','FN'};
    case 'varOP'
      varNames={'AP','AUC'};
    case 'all'
      varNames={'acc','Fscore','Prec','Rec','TP','TN','FP','FN','AP','AUC'};
    otherwise
      error('Unknown option');
  end

  for i=1:length(varNames)
    try
      value=eval(sprintf('obj.%s',varNames{i}));
      if ~isempty(value)
        fprintf('\t%s:%d\n',varNames{i},value);
      end
    catch err
      disp(getReport(err));
    end
  end
  fprintf('DATA ');
  if ~isempty(obj.posFrac)
    fprintf('(+:%f,-:%f) of ', obj.posFrac,1-obj.posFrac);
  else
    fprintf('unknown, ');
  end
  if ~isempty(obj.posFrac)
    fprintf('%d samples', obj.numSamples);
  else
    fprintf('unknown');
  end
  fprintf('\n');
end  
