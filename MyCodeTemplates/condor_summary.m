function records=condor_summary(varargin)
  if isdeployed
    fprintf('Input arguments\n');
    display(varargin);    
  end  
  funcParams=parseArgs(varargin);
  % plotting settings
  set(0,'defaultlinelinewidth',3);
  set(0,'defaultaxeslinewidth',3);
  set(0,'defaulttextinterpreter','None')
  
  if isdeployed
    fprintf('Parsed parameters: \n');
    display(funcParams);
  end

  % find all relevant matfiles
  %matfiles=[];
  for i=1:length(funcParams.cluster)
    tmp=dir(sprintf('%s/RES*%d*.mat', funcParams.folder, funcParams.cluster(i)));
    %tmp=struct('name', 'trial_set2_0_0.mat');
    fprintf('Found %d matfiles from cluster %d\n', length(tmp), funcParams.cluster(i));
    if exist('matfiles')
      matfiles(end+1:end+length(tmp))=tmp(:);
    else
      matfiles=tmp;
    end
  end
  % find relevant parameters within every file
  numRecords=length(matfiles);
  %records(numRecords)=struct('matfilename', {}, 'params', {}, 'cluster', {}, 'process', {}, 'AP', {}, 'APsplit', {});
  for msno=1:length(funcParams.perfMeasure)
    perfMeasure=funcParams.perfMeasure{msno};
    if numRecords>0
    for fileno=1:numRecords
      fprintf('Processing fileno %d ...\n', fileno);
      records(fileno).matfilename=matfiles(fileno).name;
      % load all required values
      load([funcParams.folder '/' matfiles(fileno).name], 'params', sprintf('%sMat',perfMeasure), 'methodNames');
      if exist([perfMeasure 'Mat'], 'var')
        eval(sprintf('scoreMat=%sMat;',perfMeasure));
      else
        continue;
      end
      records(fileno).params=params;
      records(fileno).cluster=params.cluster;
      records(fileno).process=params.process;
      %records(fileno).attrScores=kindwiseScores(end-1);
      %if ~isempty(funcParams.baseMethod)
      %  for j=1:length(funcParams.baseMethod)
      %    baseNo=find(strcmp(methodNames, funcParams.baseMethod(j)));
      %    records(fileno).baseScores(j)=mean(scoreMat(:,baseNo));
      %  end
      %else
      %  for j=1:length(funcParams.baseMethod)
      %    records(fileno).baseScores(j)=NaN;
      %  end
      %end
      for j=1:length(funcParams.methodList)
        methodNo=find(strcmp(methodNames, funcParams.methodList{j}));
        if ~isempty(methodNo)
          records(fileno).scores(j)=mean(scoreMat(:,methodNo));
        else
          records(fileno).scores(j)=NaN;
        end
        %records(fileno).nClauses=params.nClauses;
        %records(fileno).clauseLength=params.clauseLength;
     end
     records(fileno).RFsplits=params.RFsplits;
     records(fileno).RFdepth=params.RFdepth;
     records(fileno).RFtrees=params.RFtrees;
     records(fileno).RFpriorFrac=params.RFpriorFrac;
     records(fileno).svm_c=params.svm_c;
     records(fileno).nClauses=params.nClauses;
     records(fileno).clauseLength=params.clauseLength;
     try
       records(fileno).srcDsWt=params.srcDsWt;
     catch
     end

    
      %resultVars=strcat(params.selMethodNames,'Res');
      %load([params.folder '/' matfiles(fileno)], resultVars{:});
      %resultVars=strcat('[', resultVars, '.', perfMeasure, ']');
      %methodNames=params.selMethodNames;
    end

    % present results
    figure, 
    set(gcf,'DefaultAxesColorOrder',[1 0 0]);
    subplot(2,1,1), 
    set(gca,'defaultlinelinewidth',1);
    set(gca,'LineStyleOrder',{'o'});
    set(gca,'NextPlot','replacechildren');
      
    %plot([records.nClauses], [records.attrScores], 'r*'); hold on;
    %hold on,
    allScores=[records.scores];
    allScores=reshape(allScores, length(funcParams.methodList), length(records))';
    
    plot(1:length(funcParams.methodList), allScores'); xlim([0, length(funcParams.methodList)+1]);
    hold on, errorbar(nanmean(allScores), nanstd(allScores),'kx');
    set(gca,'XTick',1:length(funcParams.methodList), 'XTickLabel', funcParams.methodList);
    
    
    try
      set(gcf,'DefaultAxesColorOrder',[1 0 0;0 1 0;0 0 1]);
      subplot(2,1,2);
      set(gca,'LineStyleOrder',{'*','+','o','v','x','s','d'});
      set(gca,'NextPlot','replacechildren');
    param_axis=log([records.svm_c])/log(10); % set this to be whatever parameter we want to check score variation as a function of
    %param_axis=[records.clauseLength]; 
    plot(param_axis, allScores);
    
    % mean and std plots
    mainMethod=1;
    levels=unique(param_axis);
    for i=1:length(levels)
      currLevel=levels(i);
      ind=find(param_axis==currLevel);
      mainMean(i)=mean(allScores(ind,mainMethod));
      mainStd(i)=std(allScores(ind,mainMethod));
    end 
      %plot(levels, classScoreMean, 'b-');
      %plot(levels, baseScoreMean, 'r-');
      hold on, errorbar(levels, mainMean, mainStd, 'kx');
      
      legend(funcParams.methodList{:});
      xlabel('srcDsWt');
    catch
    end
      
    
    
    %subplot(2,1,2),
    %hold on,
    %if ~isempty(baseScores)
    %  plot([records.RFsplits], [baseScores], 'ro');
    %else
    %  plot([records.RFpriorFrac], 0*classScores, 'ro');  
    %end
    %plot([records.RFsplits], [classScores], 'bd');
    %legend('baseScores', 'classScores');
    %xlabel('RFsplits');
    
    fileName=params.filenameHeader;
    titleSuffix=params2title(params, params.titleFieldNames);
    suptitle(sprintf('%s:%s [Cluster %d]', fileName, titleSuffix, funcParams.cluster));
    end
  end

%   subplot(2,1,2), 
%   plot([records.clauseLength], [records.attrScores], 'r*'); hold on;
%   plot([records.clauseLength], [records.classScores], 'bd');
%   legend('attrScores', 'classScores');
%   xlabel('clauseLength');
end

function params= parseArgs(args)
  params.cluster=0;
  %params.folder=pwd;
  params.folder='condor/Figs/';
  %params.methodList={'RF_DNF','RF_CNJ','RF_plain','cascForest','multiRF', 'multiCascRF'};
  params.methodList={'feat','RF_plain','RF_CNJ','RF_DNF','multiRF','cascFor_plain', 'cascForest', 'multiCascRF', 'RF_adapt'};
  %params.methodList={'RF_adapt'};
  
  params.perfMeasure={'AP','AUC','Fscore'};
  
  numarg=length(args);
  assert(mod(numarg,2)==0);
  if numarg>=2
    for i=1:2:numarg
      switch args{i}
        case 'cluster'
          params.cluster=convert2num(args{i+1});
        case 'folder'
          params.folder=args{i+1};
        case 'methodList'
          params.methodList=args{i+1};
        case 'baseMethod'
          params.baseMethod=args{i+1};
        case 'perfMeasure'
          params.perfMeasure=args{i+1};
        otherwise
          error(sprintf('Unknown parameter %s', args{i}));
      end
    end
  end
  
  if ~iscell(params.perfMeasure)
    params.perfMeasure={params.perfMeasure};
  end
  if ~iscell(params.methodList)
    params.methodList={params.methodList};
  end
end

function arg = convert2num(arg)
  if isdeployed
    arg=eval(arg);
  end
end
