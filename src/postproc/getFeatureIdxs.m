function idxs = getFeatureIdxs( fDescription, varargin )
% GETFEATUREIDXS get all feature indexes of particular groups
%
% fdescription -- feature set description as produced by AMLTTP
% varargin -- groups labels forming the intersected subset for which feature
% indexes will be returned

%%

idxs = [];
nidxs = 1 : numel( fDescription );

lidxs = true( size( fDescription ) );
for jj = 1 : numel( varargin )
    if ischar( varargin{jj} )
        lidxs = lidxs & cellfun( @(fd)(any( strcmp( varargin{jj}, fd ) )), fDescription );
    else
        lidxs = lidxs & cellfun( @(fd)(eq( varargin{jj}, fd )), fDescription );
    end
end
idxs = unique( [idxs, nidxs(lidxs)] );
