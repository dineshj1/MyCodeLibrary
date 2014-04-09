function c = multi_km( n,xtr,r )
% This function calls kmeans multiple times and picks the clustering which
% gives smallest error.

c_temp = zeros(size(xtr,1),n,r);
err = zeros(r,1);
for i=1:r
    [~,c_temp(:,:,i),err(i)] = kmeansML (n,xtr);
end

[~, I] = min(err);
c = c_temp(:,:,I);

end

