function [labels, identities, idFiles] = makeLabels( dfiles, soundsDir, className, esetup )

fprintf( 'make labels ' );

labelsSaveName = [soundsDir '/' className '/' className '_' getLabelsHash( esetup, dfiles ) '.labels.mat'];
if ~exist( labelsSaveName, 'file' )
    
    labels = [];
    identities = [];
    for i = 1:length( dfiles.soundFileNames )
        
        fprintf( '.' );
        
        blocksSaveName = [dfiles.soundFileNames{i} '.' getBlockDataHash( esetup ) '.blocks.mat'];
        ls = load( blocksSaveName, 'wp2BlockFeatures' );
        wp2BlockFeatures = ls.wp2BlockFeatures;
        
        if ~isempty( cell2mat( strfind( dfiles.classSoundFileNames, dfiles.soundFileNames{i} ) ) )
            blockLabels = labelBlocks( dfiles.soundFileNames{i}, wp2BlockFeatures, esetup );
        else
            blockLabels = -1 * ones( size( wp2BlockFeatures, 2 ), 1 );
        end
        
        labels = [labels; blockLabels];
        
        identities = [identities; repmat( [i, dfiles.classNames{i,2}], size( wp2BlockFeatures, 2 ), 1 )];
        
    end
    idFiles = dfiles.soundFileNames;
    
    save( labelsSaveName, 'labels', 'identities', 'idFiles', 'esetup' );
else
    load( labelsSaveName, 'labels', 'identities', 'idFiles' );
end

disp( ';' );