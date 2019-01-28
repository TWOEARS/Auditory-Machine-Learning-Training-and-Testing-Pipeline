function idxs = getFeatureIdxs( fDescription, varargin )
% GETFEATUREIDXS get all feature indexes of particular groups
%
% fdescription -- feature set description as produced by AMLTTP
% varargin -- cells of groups labels forming intersected subsets for which feature
% indexes will be returned

%%

idxs = [];
nidxs = 1 : numel( fDescription );

for ii = 1 : numel( varargin )
    lidxs = true( size( fDescription ) );
    for jj = 1 : numel( varargin{ii} )
        if ischar( varargin{ii}{jj} )
            lidxs = lidxs & cellfun( @(fd)(any( strcmp( varargin{ii}{jj}, fd ) )), fDescription );
        else
            lidxs = lidxs & cellfun( @(fd)(eq( varargin{ii}{jj}, fd )), fDescription );
        end
    end
    idxs = unique( [idxs, nidxs(lidxs)] );
end
