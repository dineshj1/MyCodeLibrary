classdef binClassRes< handle
  properties (SetAccess=public, GetAccess=public)
    acc;Fscore;Prec;Rec;TP;TN;FP;FN; % measures at single operating point
    AP; AUC; % performance measures across operating points
    numSamples;posFrac; % conditions in the testing data, can also be set with setRes using the 'any' option
    pred; conf; % per-instance scores on which the performance measures are computed

    misc; % to hold variables that we do not currently use
  end
  methods (Access=public)
    % set results
    setRes(varargin);

    % print results
    dispRes(varargin);

    % TODO compute results from given predictions and ground truth (copy from classifyData)
  end
end 
