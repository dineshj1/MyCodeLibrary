function model = forestTrain(X, Y, opts, targetDNF)
    % X is (a cell array of ) NxD matrices, where rows are data points
    % for convenience, for now we assume X is 0 mean unit variance. If it
    % isn't, preprocess your data with
    %
    % X= bsxfun(@rdivide, bsxfun(@minus, X, mean(X)), var(X) + 1e-10);
    %
    % If this condition isn't satisfied, some weak learners won't work out
    % of the box in current implementation.
    %
    % Y is ( a cell array of ) discrete Nx1 vector of labels
    % model can be plugged into forestTest()
    %
    % decent default opts are:
    % opts.depth= 9;
    % opts.numTrees= 100; %(but more is _ALWAYS_ better, monotonically, no exceptions)
    % opts.numSplits= 5;
    % opts.classifierID= 2
    % opts.classifierCommitFirst= true;
    %
    % which means use depth 9 trees, train 100 of them, use 5 random
    % splits when training each weak learner. The last option controls
    % whether each node commits to a weak learner at random and then trains
    % it best it can, or whether each node tries all weak learners and
    % takes the one that does best. Empirically, it appears leaving this as
    % true (default) gives slightly better looking results.
    %
    
    numTrees= 100;
    verbose= true;
    priorMethod='varSel';
    if ~iscell(X) % from now on, X will be a cell array, with each cell containing one dataset
      X={X};
      Y={Y};
    end
    assert(length(X)==length(Y));
    
    if nargin < 3, opts= struct; end
    if nargin < 4, D=size(X{1},2); targetDNF=zeros(1,D); end % will lead to uniform prior at each stage
    targetDNF=(targetDNF+eps)/max(targetDNF(:)+eps);
    
    if isfield(opts, 'numTrees'), numTrees= opts.numTrees; end
    numTrees=max(numTrees,1); % preventing empty forests
    if isfield(opts, 'verbose'), verbose= opts.verbose; end
    if isfield(opts, 'priorMethod'),priorMethod= opts.priorMethod; end
    treePrior=struct('targetDNF', targetDNF, 'priorMethod', priorMethod);
    treeModels= cell(1, numTrees);
    for i=1:numTrees
        % TODO? have a bagging option i.e. each tree is trained on a randomly chosen subset of data
        treeModels{i} = treeTrain(X, Y, opts, treePrior);
        
        % print info if verbose
        if verbose
            p10= floor(numTrees/10);
            if mod(i, p10)==0 || i==1 || i==numTrees
                fprintf('Training tree %d/%d...\n', i, numTrees);
            end
        end
    end
    
    model.treeModels = treeModels;
end
