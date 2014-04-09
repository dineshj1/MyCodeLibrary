function [a,b,c,d] = confusion_mat(output,ytrain,tr)
% This function calculates confusion matrix from labels and predictions
% given a specific threshold.

o = output > tr;
y = ytrain;
ind = find(o ~= y);
a = 0;
b = 0;
c = 0;
d = 0;
for i=1:length(ind)
    p = o(ind(i));
    t = y(ind(i));
    if p == 0 && t == 1
        c = c + 1;
    else
        b = b + 1;
    end
end

ind = find(o == y);

for i=1:length(ind)
    if o(ind(i)) == 0
        a = a + 1;
    else
        d = d + 1;
    end
end

% BER = 0.5*(b/(a+b) + c/(c+d))
        