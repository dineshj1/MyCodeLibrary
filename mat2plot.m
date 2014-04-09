function mat2plot(matfilename, saveFigs)
  if nargin<2
    saveFigs=0;
  end
  addLib;
  makeLine(sprintf('CP2: Loading from  %s', matfilename),'|',100);
  load(matfilename);

  %% Presenting results
  % basic: show AP for all concepts for all methods
  perfMeasure='AP';
  makeLine(sprintf('Generating %s plots for all methods', perfMeasure),'.',50,0);
  APfig=drawFigure;
  resultVars=strcat(params.selMethodNames,'Res(higherConcepts)');
  resultVars=strcat('[', resultVars, '.', perfMeasure, ']');
  methodNames=params.selMethodNames;
  
  scoreMat=[];
  LEG={};
  assert(length(resultVars)==length(methodNames),'Incorrect number of method names or result variables');
  for methodNo=1:length(methodNames)
    scores=eval(resultVars{methodNo}); % row vector
    scoreMat=[scoreMat scores'];
    LEG{methodNo}=sprintf('%s:%f', methodNames{methodNo}, mean(scores));
  end
  bar(scoreMat);legend(LEG{:});  
  xlim(gca, [1 numConcept]); set(gca, 'XTick', 1:length(concepts), 'XTickLabel', {concepts.name}); rotateXLabels(gca, 90); 
  if saveFigs
    storeFigs(APfig,sprintf('%s/%s_APs-%d-%d_%d%s',  params.OPfolder, params.filenameHeader, params.subSplitNo, params.cluster, params.process, params.figFormat));
  end

  % show evolution of score over revisions
  
  if ismember('bootstrap', params.selMethodNames)
    makeLine(sprintf('Plotting score evolution over revisions'),'.',50,0);
    try
      tmp=[featRes.AP];
      tmp2=reshape([stagedBootstrapRes.AP], params.numRevisions, numConcept);
      scoreMat=[tmp; tmp2];
      RevisionFig=drawFigure;
      bar(scoreMat');
      methodScoreStr=cellstr(num2str(mean(scoreMat,2)))';
      tmp=repmat({'revision'},params.numRevisions, 1);
      tmp=strcat(tmp, cellstr(num2str((1:params.numRevisions)')));
      methodNames={'feat', tmp{:}}; 
      LEG=strcat(methodNames, ': ', methodScoreStr);
      legend(LEG{:});
      xlim(gca, [1 numConcept]); set(gca, 'XTick', 1:length(concepts), 'XTickLabel', {concepts.name}); rotateXLabels(gca, 90); 
      if saveFigs
        storeFigs(RevisionFig,sprintf('%s/%s_Revisions-%d-%d_%d%s',  params.OPfolder, params.filenameHeader, params.subSplitNo, params.cluster, params.process, params.figFormat));
      end
    catch err
      getReport(err)
      abort
    end
  end

  % show dependencies among attributes (just display weight vectors)
  if ismember('bootstrap', params.selMethodNames)
    makeLine(sprintf('Plotting dependencies among attributes (last layer weights)'),'.',50,0);
    try
      try   
        numFeatures=size(instances,2)+numCon2;
      catch
        numFeatures=bootstrapClassifier(1).nr_feature;
      end
      %wtVecMat=reshape([wtVecMat],numFeatures, numConcept)';

      dependFig=drawFigure;
      if ~exist('wtVecMat')      
        wtVecMat=reshape([bootstrapClassifier.w],numFeatures, numConcept)';
      end
      imagesc(abs(normr(wtVecMat)));
      %xlim(gca, [1 numFeatures]); set(gca, 'XTick', size(instances,2)+(1:numConcept), 'XTickLabel', {concepts.name}); rotateXLabels_im(gca, 90); 
      xlim(gca, [1 numFeatures]); 
      ylim(gca, [1 numConcept]); set(gca, 'YTick', 1:numConcept, 'YTickLabel', {concepts.name}); 
      if saveFigs
        storeFigs(dependFig,sprintf('%s/%s_structure-%d-%d_%d%s', params.OPfolder, params.filenameHeader, params.subSplitNo, params.cluster, params.process, params.figFormat));
      end
    catch err
      getReport(err)
      abort
    end
  end

  if ismember('bootstrap', params.selMethodNames) && params.addComposites
    makeLine(sprintf('Plotting composites added'));
    try
      figure, imagesc(reshape([composites.concepts], numConcept, length(composites))')
      if params.figSave || params.Dep.condor 
        storeFigs(dependFig,sprintf('%s/%s_composites-%d-%d_%d%s', params.OPfolder, params.filenameHeader, params.subSplitNo, params.cluster, params.process, params.figFormat));
      end
    catch
      getReport(err)
      abort
    end
  end 

 % show "discovered" structure i.e the levels of concepts
  if ismember('final', params.selMethodNames)
    makeLine(sprintf('Plotting discovered structure'),'.',50,0);
    try
      structFig=drawFigure;
      subplot(2,1,1), plot(1:numConcept,zeros(numConcept,1)); xlim([0 numConcept+1]);
      for i=1:length(levelMembers)
        currlevel=i;
        ylim([0 currlevel+2]);
        for j=1:length(levelMembers{i})
          conceptno=levelMembers{i}(j);
          text(conceptno, currlevel, concepts(conceptno).name, 'Rotation', 90);
        end
      end

      makeLine(sprintf('Plotting improvements'),'.',50,0);
      subplot(2,1,2), bar(improvementMat'); % plotting improvements over learning from features alone 
      xlim([0 numConcept+1]);  
      xlabel('concepts');
      ylabel('improvements'); 
      if saveFigs
        storeFigs(structFig,sprintf('%s/%s_structure-%d-%d_%d%s', params.OPfolder, params.filenameHeader, params.subSplitNo, params.cluster, params.process, params.figFormat));
      end
    catch err
      getReport(err)
      abort
    end
  end 
end
