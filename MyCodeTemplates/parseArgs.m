function params=parseArgs(args)
  params.condor=false;
  params.useClassFreq=false;
  params.redo=false;
  params.cluster=0;
  params.process=0;
  params.figSave=false;
  params.figFormat='png';
  params.OPfolder=pwd;
  params.titleFieldNames={'PCA','logReg_c','dbn_alpha','dbn_momentum', 'dbn_numepochs'};
  % default values of all list parameters
  params.List.logReg_c=1;
  params.List.PCA=1;
  params.List.dbn_momentum  =   0;
  params.List.dbn_alpha     =   1; 
  params.List.dbn_numepochs =   1;
  params.List.dbn_batchsize = 100;
 
  defaultTTLFields=true;

  numarg = length(args);
  if numarg>=2
    for i=1:2:numarg
      switch args{i}
        case 'redo'
          params.redo=convert2num(args{i+1});
        case 'useClassFreq'
          params.useClassFreq=convert2num(args{i+1});
        case 'selectedMethods'
          params.selectedMethods=convert2num(args{i+1});
        case 'cluster'
          params.cluster=convert2num(args{i+1});
        case 'ttl_fields'
          defaultTTLFields=false;
          param.titleFieldNames=eval(args{i+1}); case 'process'
          params.condor=true;
          params.process=convert2num(args{i+1});
        case 'figFormat'
          params.figSave=true;
          params.figFormat=args{i+1};        
        case 'figSave'
          params.figSave=convert2num(args{i+1});
        case 'OPfolder'
          params.OPfolder=args{i+1};

      % all "List" parameters (meant to be easily changed through condor)
        case 'logReg_cList'
          param.List.logReg_c=convert2num(args{i+1});
        case 'PCAList'
          params.List.PCA=convert2num(args{i+1});
        case 'dbn_momentumList'
          params.List.dbn_momentum  = convert2num(args{i+1});
        case 'dbn_alphaList'
          params.List.dbn_alpha     = convert2num(args{i+1});
        case 'dbn_epochsList'
          params.List.dbn_numepochs = convert2num(args{i+1});
        case 'dbn_batchsizeList'
          params.List.dbn_batchsize = convert2num(args{i+1}); 
        otherwise
          error(sprintf('invalid parameter name %s', args{i}));
      end
    end
  end
  mkdir(params.OPfolder);
  %if params.condor
    % selecting item from list
    fprintf('\nCombinations');
    paramNames=fieldnames(params.List);
    for i = 1:length(paramNames)
      tmp{i}=eval(sprintf('params.List.%s',paramNames{i}));
    end
    combinations = allcomb(tmp{:});
    disp([(1:size(combinations,1))' combinations]);
    fprintf('\n Selecting parameter combination #'); 
    params.index = params.process;
    fprintf('%d(+1) of %d\n\n', params.index, size(combinations,1));
    assert(params.index+1<=size(combinations,1) && params.index>=0);
    for i=1:length(paramNames)
      eval(sprintf('params.%s=combinations(params.index+1,%d)', paramNames{i}, i));
    end
  %end
end  

function arg = convert2num(arg)
  if isdeployed
    arg=eval(arg);
  end
end
 
