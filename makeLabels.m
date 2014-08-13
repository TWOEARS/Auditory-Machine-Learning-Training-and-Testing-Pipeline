function [labels, identities, idFiles] = makeLabels( soundsDir, className, esetup )

fprintf( 'make labels ' );

[classSoundFileNames, soundFileNames, classNames] = makeSoundLists( soundsDir, className );

labelsSaveName = [soundsDir '/' className '/' className '_' getLabelsHash( esetup ) '.labels.mat'];
if ~exist( labelsSaveName, 'file' )
    
    labels = [];
    identities = [];
    for i = 1:length( soundFileNames )
        
        fprintf( '.' );
        
        blocksSaveName = [soundFileNames{i} '.' getBlockDataHash( esetup ) '.blocks.mat'];
        ls = load( blocksSaveName, 'wp2BlockFeatures' );
        wp2BlockFeatures = ls.wp2BlockFeatures;
        
        if ~isempty( cell2mat( strfind( classSoundFileNames, soundFileNames{i} ) ) )
            blockLabels = labelBlocks( soundFileNames{i}, wp2BlockFeatures, esetup );
        else
            blockLabels = -1 * ones( size( wp2BlockFeatures, 2 ), 1 );
        end
        
        labels = [labels; blockLabels];
        
        identities = [identities; repmat( [i, classNames{i,2}], size( wp2BlockFeatures, 2 ), 1 )];
        
    end
    idFiles = soundFileNames;
    
    save( labelsSaveName, 'labels', 'identities', 'idFiles', 'esetup' );
else
    load( labelsSaveName, 'labels', 'identities', 'idFiles' );
end

disp( ';' );