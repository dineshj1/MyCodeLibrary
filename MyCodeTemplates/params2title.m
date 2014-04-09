function titleStr = params2title(params,fieldNames,noNames)
 if nargin<3
   noNames=false;
 end
 titleStr='';
 for i=1:length(fieldNames)
   switch noNames
     case false
       titleStr=[titleStr fieldNames{i} '-' num2str(getfield(params, fieldNames{i})) ','];
     case true
       titleStr=[titleStr ' ' num2str(getfield(params, fieldNames{i}))];
   end
 end
 if ~noNames
   titleStr=['[' titleStr(1:end-1) ']'];
 end
end 
