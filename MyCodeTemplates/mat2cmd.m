function cmdStr=mat2cmd(matfilename, fooName)
 if nargin<2
    fooName='fooName';
  end
  addLib;
  makeLine(sprintf('Loading from  %s', matfilename),'|',100);
  load(matfilename, 'params');   

  cmdStr=params2cmd(params, fooName);
end
