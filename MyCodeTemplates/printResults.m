function printResults(results, header, field, FID, preamble)
  if nargin<2
     header = '';
  end
  if nargin<3
    field='ap';
  end
  if nargin<4
    FID=[];
  end
  if nargin<5
    preamble='';
  end
  numValSets=length(results(1).val);
  numTestSets=length(results(1).test);
  numDataSets=min(numValSets, numTestSets);
  for i=1:numDataSets
      fprintf('Set#%d-%s\n%s\nVal_%s:%f (+/- %f), \nTest_%s:%f (+/- %f), \nHard_%s:%f (+/- %f)\n\n',i,header,preamble,...
          field, mean(arrayfun(@(x) getfield(x.val(i), field), results)), std(arrayfun(@(x) getfield(x.val(i), field), results)),...
          field, mean(arrayfun(@(x) getfield(x.test(i), field), results)), std(arrayfun(@(x) getfield(x.test(i), field), results)),...
          field, mean(arrayfun(@(x) getfield(x.hard(i), field), results)), std(arrayfun(@(x) getfield(x.val(i), field), results))); 
      if ~isempty(FID)
         fprintf(FID, '%s %f %f %f\n',preamble,...
          mean(arrayfun(@(x) getfield(x.val(i), field), results)),...
          mean(arrayfun(@(x) getfield(x.test(i), field), results)),...
          mean(arrayfun(@(x) getfield(x.hard(i), field), results)));
      end
  end
end 
