function [pred,dummy,decval]= liblin_predict_wrap(varargin)
  varargin{2}=sparse(varargin{2});
  if ischar(varargin{end})
    varargin{end}=' -q';
  else
    varargin{end+1}=' -q';  
  end
  [pred,dummy,decval]=liblin_predict(varargin{:});
  model=varargin{3};
  if model.Label(1)==0
    decval=-decval;
  end
  % TODO include platt scaling
  if isfield(model, 'plattScale')
    decval=1./(1+exp(decval.*model.plattScale.A+model.plattScale.B));
  end
end
