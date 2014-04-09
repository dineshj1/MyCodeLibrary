function [mappedX] = testNormalize(X,mu_X,VAR)
   
X = X';
X = bsxfun(@minus, X, mu_X);
mappedX = bsxfun(@rdivide, X, sqrt(VAR));
mappedX = mappedX';