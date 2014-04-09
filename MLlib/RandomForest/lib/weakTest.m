function yhat = weakTest(model, X, opts)
% X is NxD as usual. 
% see weakTrain for more info.

if nargin < 3, opts = struct; end

[N, D]= size(X);

switch model.classifierID
  case 1
    % Decision stump classifier
    yhat = double(X(:, model.r) < model.t);
  case 2
    % 2-D linear clussifier stump
    yhat = double([X(:, [model.r1, model.r2]), ones(N, 1)]*model.w < 0);
  case 3 
    % 2-D conic section learner
    r1= model.r1;
    r2= model.r2;
    phi= [X(:, r1).*X(:, r2), X(:,r1).^2, X(:,r2).^2, X(:, r1), X(:, r2), ones(N, 1)];
    mv= phi*model.w;
    yhat = double(mv<model.t2 & mv>model.t1);
  case 4 
    % RBF, distance based learner
    yhat= double(pdist2(X, model.x) < model.t);
  case 0 
    %no classifier was fit because there was no training data that reached
    %that leaf. Not much we can do, guess randomly.
    yhat= double(rand(N, 1) < 0.5);
  otherwise
    fprintf('Error in weak test! Classifier with ID = %d does not exist.\n', classifierID);
end


end
