function matrix=makeSparse(matrix,format) 
  switch format
    case 0
      matrix=sparse(matrix);
    case 1
      % do nothing
    otherwise
      error('Unknown format for matrix');
  end
end  
