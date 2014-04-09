function [pred,dummy,decval]= libsvm_predict_wrap(varargin)
  [pred,dummy,decval]=libsvm_predict(varargin{:});
  varargin{end}=' -q';
  model=varargin{3};
  if model.Label(1)==0
    decval=decval(:,2);
  else
    decval=decval(:,1);
  end
end 
