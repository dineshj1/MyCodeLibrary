function [mappedX] = testNormalize2(X,mu_X,COVAR)

X = X';
X = bsxfun(@minus, X, mu_X);
mappedX = X / sqrtm(COVAR);
mappedX =  mappedX';