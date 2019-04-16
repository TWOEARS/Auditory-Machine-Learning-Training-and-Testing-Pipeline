function features2text( featureDesc, idxs, fileName )
% FEATURES2TEXT extract feature set description and put to text file
% 
% featureDesc -- path to mat file with feature set description (format as
% produced by AMLTTP feature creators) OR feature set description itself
% idxs -- optional, only output selected indexes. default: all
% fileName -- name of output text file. If omitted, output to command
% window.
 
%%
if iscell( featureDesc )
    description = featureDesc;
else
    load( featureDesc, 'description' );
end

if nargin < 2 || isempty( idxs )
    idxs = 1 : numel( description ); 
elseif islogical( idxs )
    idxs = find( idxs );
end

if nargin > 2 && ~isempty( fileName )
    fid = fopen( fileName, 'w' );
else
    fid = 1;
end

if size( idxs, 1 ) ~= 1, idxs = idxs'; end

for idx = idxs
    for ii = 1 : numel( description{idx} ) 
        if ischar( description{idx}{ii} )
            fprintf( fid, '%s', description{idx}{ii} );
        else
            fprintf( fid, '%s', mat2str( description{idx}{ii} ) );
        end
        if ii < numel( description{idx} )
            fprintf( fid, '; ' );
        else
            fprintf( fid, '\n' );
        end
    end
end

if fid ~= 1, fclose( fid ); end
