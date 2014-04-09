function o = f_value(b,c,d)
% This function calculates f-score using confusion matrix.

PR = d/(b+d);
RC = d/(c+d);

o = 2*PR*RC/(PR+RC);