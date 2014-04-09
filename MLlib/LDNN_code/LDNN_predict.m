function output = LDNN_predict (x, model)
% inputs:
%       x: d by N training set ( d is number of attributes and N is
%               number of samples.
%       model: output of LDNN train.

discriminants = model.discriminants;
nGroup = model.nGroup;
nDiscriminantPerGroup = model.nDiscriminantPerGroup;
n = size(x,2);
x = [x; ones(1,n)];
output = predict(x, discriminants, nGroup, nDiscriminantPerGroup);

