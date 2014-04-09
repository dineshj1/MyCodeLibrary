function [mappedX, mu_X, VAR] = trainNormalize(X)

X = X';
mu_X = mean(X, 1);
X = bsxfun(@minus, X, mu_X);
VAR = var(X);
mappedX = bsxfun(@rdivide, X, sqrt(VAR));
mappedX = mappedX';
