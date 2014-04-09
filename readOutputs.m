% reading outputs
clusterno=27778;
datasetno=2;
params=[1 2 3 4];
foldername='condor/Figs';
filenames=dir(sprintf('%s/REC_*%d*.txt',foldername,clusterno));
mat=[];
for i=1:length(filenames)
  t=load([foldername '/' filenames(i).name]);
  mat=[mat; t(datasetno,:)];
end
mat=sortrows(mat, params);
