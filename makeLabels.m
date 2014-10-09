function [labels, identities, idFiles] = makeLabels( dfiles, soundsDir, className, setup )

fprintf( 'make labels ' );

labelsSaveName = [soundsDir '/' className '/' className '_' getLabelsHash( setup, dfiles ) '.labels.mat'];
if ~exist( labelsSaveName, 'file' )
    
    labels = [];
    identities = [];
    for i = 1:length( dfiles.soundFileNames )
        
        fprintf( '.' );
        
        blocksSaveName = [dfiles.soundFileNames{i} '.' getBlockDataHash( setup ) '.blocks.mat'];
        data = load( blocksSaveName, 'blockFeatures' );
        blockFeatures = data.blockFeatures;
        
        if ~isempty( cell2mat( strfind( dfiles.classSoundFileNames, dfiles.soundFileNames{i} ) ) )
            blockLabels = labelBlocks( dfiles.soundFileNames{i}, blockFeatures, setup );
        else
            blockLabels = -1 * ones( size( blockFeatures, 2 ), 1 );
        end
        
        labels = [labels; blockLabels];
        
        identities = [identities; repmat( [i, dfiles.classNames{i,2}], size( blockFeatures, 2 ), 1 )];
        
    end
    idFiles = dfiles.soundFileNames;
    
    save( labelsSaveName, 'labels', 'identities', 'idFiles', 'setup' );
else
    load( labelsSaveName, 'labels', 'identities', 'idFiles' );
end

disp( ';' );
