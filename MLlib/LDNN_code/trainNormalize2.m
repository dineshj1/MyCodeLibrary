function [mappedX, mu_X, COVAR] = trainNormalize2(X)

X = X';
mu_X = mean(X, 1);
X = bsxfun(@minus, X, mu_X);
COVAR = cov(X);
mappedX = X / sqrtm(COVAR);
mappedX =  mappedX';
