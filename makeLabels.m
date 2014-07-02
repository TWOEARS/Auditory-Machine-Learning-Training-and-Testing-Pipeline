function [labels, identities, idFiles] = makeLabels( soundsDir, className, niState )

fprintf( 'make labels ' );

[classSoundFileNames, soundFileNames, classNames] = makeSoundLists( soundsDir, className );

labelsSaveName = [soundsDir '/' className '/' className '_' getLabelsHash( niState ) '.labels.mat'];
if ~exist( labelsSaveName, 'file' )
    
    labels = [];
    identities = [];
    for i = 1:length( soundFileNames )
        
        fprintf( '.' );
        
        blocksSaveName = [soundFileNames{i} '.' getBlockDataHash( niState ) '.blocks.mat'];
        ls = load( blocksSaveName, 'wp2BlockFeatures' );
        wp2BlockFeatures = ls.wp2BlockFeatures;
        
        if ~isempty( cell2mat( strfind( classSoundFileNames, soundFileNames{i} ) ) )
            blockLabels = labelBlocks( soundFileNames{i}, wp2BlockFeatures, niState );
        else
            blockLabels = -1 * ones( size( wp2BlockFeatures, 1 ), 1 );
        end
        
        labels = [labels; blockLabels];
        
        identities = [identities; repmat( [i, classNames{i,2}], size( wp2BlockFeatures, 1 ), 1 )];
        
    end
    idFiles = soundFileNames;
    
    save( labelsSaveName, 'labels', 'identities', 'idFiles', 'niState' );
else
    load( labelsSaveName, 'labels', 'identities', 'idFiles' );
end

disp( ';' );