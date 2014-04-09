function model = weakTrain(X, Y, opts, prior)
% weak random learner
% can currently train:
% 1. decision stump: look along random dimension of data, choose threshold
% that maximizes information gain in class labels
% 2. 2D linear decision learner: same as decision stump but in 2D. I know,
% in general this could all be folded into single linear stump, but I make
% distinction for historical, cultural, and efficiency reasons.
% 3. Conic section learner: second order learning in 2D. i.e. x*y is a
% feature in addition to x, y and offset (as in 2.)
% 4. Distance learner. Picks a data point in train set and a threshold. The
% label is computed based on distance to the data point

classifierID= 1; % by default use decision stumps only
numSplits= 30; 
numSplitsPerVar= 5;
classifierCommitFirst= true;
dsWts=[1,0]; % dataset weights when determining information gain

if nargin < 3, opts = struct; end
if isfield(opts, 'classifierID'), classifierID = opts.classifierID; end
if isfield(opts, 'numSplits'), numSplits = opts.numSplits; end
if isfield(opts, 'numSplitsPerVar'), numSplitsPerVar = opts.numSplitsPerVar; end
if isfield(opts, 'classifierCommitFirst'), classifierCommitFirst = opts.classifierCommitFirst; end
if isfield(opts, 'dsWts'), dsWts = opts.dsWts; end

if classifierCommitFirst
    % commit to a weak learner first, then optimize its parameters only. In
    % this variation, different weak learners don't compete for a node.
    if length(classifierID)>1
        classifierID= classifierID(randi(length(classifierID)));
    end
end

if ~iscell(X)
  X={X};
  Y={Y};
end

u= unique(Y{1});
[~, D]= size(X{1});
numDatasets=length(X);

if nargin < 4, prior = struct('pdf', ones(1,D)/D, 'priorMethod', '', 'threshMethod', ''); end % uniform prior
% Making sure prior has all required fields etc.
if ~isfield(prior, 'pdf')
  prior.pdf=ones(1,D)/D;
elseif isempty(prior.pdf)
  prior.pdf=ones(1,D)/D;
end

if ~isfield(prior, 'priorMethod')
  prior.priorMethod='varSel';
elseif isempty(prior.priorMethod)
  prior.priorMethod='varSel';
end 

if ~isfield(prior, 'threshMethod') % option not functional any more
  prior.threshMethod='';
end

assert(length(prior.pdf)==D, sprintf('prior.pdf must be a D(=%d)-length vector',D));
assert(all(prior.pdf>=0), 'prior pdf must be non-negative');

% setting boundaries variable (cdf used in variable selection)
switch prior.priorMethod
  case 'varSel' % prior on variable selection
    boundaries=cumsum(prior.pdf);
  case 'splitEval' % prior used in assigning scores to splits
    boundaries=cumsum(ones(1,D)/D); % making boundaries into the cdf of a uniform distribution so that no bias is used in variable selection
  otherwise
    error(sprintf('Unknown priorMethod %s', prior.priorMethod));
end
%assert(boundaries(end)==1, 'Prior probabilties do not add to 1'); % not
%necessary. Compensated for later when dropping pin.
N=0;
for dsno=1:numDatasets
  N=N+size(X{dsno},1);
end

if N == 0 % no samples in any dataset
    % edge case. No data reached this leaf. Don't do anything...
    model.classifierID= 0;
    model.r=[];
    model.Igain_net=[];
    model.Igain_ds=[];
    return;
end
        
bestgain= -Inf;
model = struct;
% Go over all applicable classifiers and generate candidate weak models
for classf = classifierID

    modelCandidate= struct;    
    maxgain_net= -Inf;
    %maxgain_ds= -Inf*ones(1,numDatasets);

    if classf == 1
        % Decision stump

        % proceed to pick optimal splitting value t, based on Information Gain  
        for q= 1:numSplits
            
            if mod(q-1,numSplitsPerVar)==0
                % drop a pin and find the bin (bins specified by boundaries) that the pin drops in
                pindrop=rand(1)*boundaries(end); 
                tmp=find(pindrop<boundaries);
                r=tmp(1); % selected variable
                
                tmin=Inf; tmax=-Inf;
                levs=[];
                for dsno=1:numDatasets
                  col= X{dsno}(:, r);
                  levs=union(levs,unique(col));
                  if ~isempty(col)
                    tmin= min(tmin,min(col));
                    tmax= max(tmax,max(col));
                  end
                end
                clear('col');
                  % temporary(?)
                  tmin=0; tmax=1;
            end
            
            % setting threshold
            if length(levs)>2
              t=rand(1);            
              t= t*(tmax-tmin)+tmin; 
            elseif ~isempty(levs)
              t=mean(levs);
            else
              t=0;
              warning('No unique values?? Something fishy!');
            end
                
%             switch prior.threshMethod % not being used at this stage
%               case 'dummy'
%               %case 'meansep' % one way to bias the threshold to be close to the best separating value?
%               %  % NOTE that this is not side-information based, so it is not important to us at this point 
%               %  meanpos=mean(col(Y==1));
%               %  meanneg=mean(col(Y~=1));
%               %  threshmean=meanpos+meanneg/2;
%               %  threshsigma=meanpos-meanneg;
%               %  if isnan(threshmean)
%               %    threshmean=0;
%               %    threshsigma=mean(col);
%               %  end
%               %  t=min(max(normrnd(threshmean, threshsigma),tmin),tmax);
%               otherwise
%                 t=rand(1);
%                 %t,tmax,tmin  
%                 t= t*(tmax-tmin)+tmin; 
%             end
             
            Igain_net=0;
            for dsno=1:numDatasets
              col = X{dsno}(:, r); 
              dec = col < t;
              Igain_ds(dsno) = evalDecision(Y{dsno}, dec, u);
              if strcmp(prior.priorMethod, 'splitEval')
                % Igain should be multiplied by the prior for that particular variable?  
                Igain_ds(dsno)=Igain_ds(dsno)*prior.pdf(r); 
              end
              if ~isnan(Igain_ds(dsno))
                Igain_net=Igain_net+Igain_ds(dsno)*dsWts(dsno);
              else
                Igain_net=Igain_net-1; % -1 is equal to worst possible information gain value from two class data
              end
            end

            if Igain_net>maxgain_net
              maxgain_net = Igain_net;
              maxgain_ds = Igain_ds;
              modelCandidate.r= r;
              modelCandidate.t= t;
              if ~isdeployed
                % temporary
                modelCandidate.Igain_net= Igain_net;
                modelCandidate.Igain_ds= Igain_ds;
              end
            end
        end

    elseif classf == 2
        % Linear classifier using 2 dimensions

        % Repeat some number of times: 
        % pick two dimensions, pick 3 random parameters, and see what happens
        for q= 1:numSplits

            r1= randi(D);
            r2= randi(D);
            w= randn(3, 1);
            
            dec = [X(:, [r1 r2]), ones(N, 1)]*w < 0;
            Igain = evalDecision(Y, dec, u);
            
            if Igain>maxgain
                maxgain = Igain;
                modelCandidate.r1= r1;
                modelCandidate.r2= r2;
                modelCandidate.w= w;
            end
        end

    elseif classf == 3
        % Conic section weak learner in 2D (not too good presently, what is the
        % best way to randomly suggest good parameters?

        % Pick random parameters and see what happens
        for q= 1:numSplits

            if mod(q-1,5)==0
                r1= randi(D);
                r2= randi(D);
                w= randn(6, 1);
                phi= [X(:, r1).*X(:, r2), X(:,r1).^2, X(:,r2).^2, X(:, r1), X(:, r2), ones(N, 1)];
                mv= phi*w;
            end
            
            t1= randn(1);
            t2= randn(1);
            if rand(1)<0.5, t1=-inf; end
            dec= mv<t2 & mv>t1;
            Igain = evalDecision(Y, dec, u);

            if Igain>maxgain
                maxgain = Igain;
                modelCandidate.r1= r1;
                modelCandidate.r2= r2;
                modelCandidate.w= w;
                modelCandidate.t1= t1;
                modelCandidate.t2= t2;
            end
        end

    elseif classf==4
        % RBF weak learner: Picks an example and bases decision on distance
        % threshold
        
        % Pick random parameters and see what happens
        for q= 1:numSplits

            % this is expensive, lets only recompute every once in a while...
            if mod(q-1,5)==0
                x= X(randi(size(X, 1)), :);
                dsts= pdist2(X, x);
                maxdsts= max(dsts);
                mindsts= min(dsts);
            end

            t= rand(1)*(maxdsts - mindsts)+ mindsts;
            dec= dsts < t;
            Igain = evalDecision(Y, dec, u);

            if Igain>maxgain
                maxgain = Igain;
                modelCandidate.x= x;
                modelCandidate.t= t;
            end
        end

    else
        fprintf('Error in weak train! Classifier with ID = %d does not exist.\n', classf);
    end

    % see if this particular classifier has the best information gain so
    % far, and if so, save it as the best choice for this node
    if maxgain_net >= bestgain
        bestgain = maxgain_net;
        model= modelCandidate;
        model.classifierID= classf;
    end

end

end

function Igain= evalDecision(Y, dec, u)
% gives Information Gain provided a boolean decision array for what goes
% left or right. u is unique vector of class labels at this node

    YL= Y(dec);
    YR= Y(~dec);
    H= classEntropy(Y, u);
    HL= classEntropy(YL, u);
    HR= classEntropy(YR, u);
    Igain= H - length(YL)/length(Y)*HL - length(YR)/length(Y)*HR;

end

% Helper function for class entropy used with Decision Stump
function H= classEntropy(y, u)

    cdist= histc(y, u) + 1;
    cdist= cdist/sum(cdist);
    cdist= cdist .* log(cdist);
    H= -sum(cdist);
    
end
