function [target_names] = splitTargetNames(fpath)

[~, fname, ~] = fileparts( fpath );
c = strsplit( fname, '-' );
target_names = strsplit( c{1}, '_' );

end