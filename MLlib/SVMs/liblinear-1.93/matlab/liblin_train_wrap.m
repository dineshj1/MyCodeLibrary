function [model]= liblin_train_wrap(varargin)
  varargin{2}=sparse(varargin{2});
  if ischar(varargin{end})
    %varargin{end}=' -q';
  else
    varargin{end+1}=' -q';  
  end
  model=liblin_train(varargin{:});

  % TODO include platt scaling
  [~,~,decval]=liblin_predict(varargin{1},varargin{2},model,'-b 1 -q');
  if model.Label(1)==0
    decval=-decval;
  end
  % fit logistic function from decval to probabilities
  target=varargin{1}==1;
  prior0=sum(target==0);
  prior1=sum(target==1);
  [model.plattScale.A, model.plattScale.B]=plattScale(decval, target, prior1, prior0);
end

function [A,B]= plattScale(out,target,prior1,prior0)
  A = 0;
  B = log((prior0+1)/(prior1+1));
  hiTarget = (prior1+1)/(prior1+2);
  loTarget = 1/(prior0+2);
  t=zeros(length(target),1);
  t(target)=hiTarget;
  t(~target)=loTarget;
   
  lambda = 1e-3;
  olderr = 1e300;
  pp =  (prior1+1)/(prior0+prior1+2)*ones(length(out),1);
  count = 0;
  for it = 1:100 
    % First, compute Hessian & gradient of error function
    % with respect to A & B
    pp=pp-t;
    a=sum(pp.*(1-pp).*out.^2);
    b=sum(pp.*(1-pp));
    c=sum(out.*pp.*(1-pp));
    d=sum(out.*(pp-t));
    e=sum(pp-t);
    
    % If gradient is really tiny, then stop
    if (abs(d) < 1e-9 && abs(e) < 1e-9)
      break
    end
    oldA = A;
    oldB = B;
    err = 0;

    % Loop until goodness of fit increases
    while (1)
      determ = (a+lambda)*(b+lambda)-c.*c;
      if (determ == 0) % if determinant of Hessian is zero
        % increase stabilizer
        lambda =lambda*10;
        continue;
      end
      A = oldA + ((b+lambda)*d-c*e)/determ;
      B = oldB + ((a+lambda)*e-c*d)/determ;
      
      % Now, compute the goodness of fit
      p=1./(1+exp(out.*A+B));
      pp=p;
      err=-sum(t.*max(log(p),-200)+(1-t).*max(log(1-p),-200));
      
      if (err < olderr*(1+1e-7))
        lambda = lambda*0.1;
        break;
      end

      % error did not decrease: increase stabilizer by factor of 10
      % & try again
      lambda= lambda*10;
      if (lambda >= 1e6) %something is broken. Give up
        break;
      end
    end
    diff = err-olderr;
    scale = 0.5*(err+olderr+1);
    if (diff > -1e-3*scale && diff < 1e-7*scale)
      count=count+1;
    else
      count = 0;
    end
    olderr = err;
    if (count == 3)
      break;
    end
  end
end
