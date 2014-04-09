function ds = mat2dataset(mat, names)
	ds = dataset({mat(:,:) names{:}});
end
