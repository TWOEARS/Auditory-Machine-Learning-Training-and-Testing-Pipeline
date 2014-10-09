function [features] = makeFeatures( dfiles, soundsDir, setup )

fprintf( 'make features' );

featuresSavePreStr = [soundsDir '/' getFeaturesHash( setup, dfiles )];
featuresSaveName = [featuresSavePreStr '.features.mat'];
if ~exist( featuresSaveName, 'file' )
    
    features = [];
    for i = 1:length( dfiles.soundFileNames )
        
        fprintf( '.' );
        
        blocksSaveName = [dfiles.soundFileNames{i} '.' getBlockDataHash( setup ) '.blocks.mat'];
        data = load( blocksSaveName, 'blockFeatures' );
        auditoryFrontEndBlockFeatures = data.blockFeatures;
        
        blockFeatures = makeFeaturesFromAuditoryFrontEndBlocks( auditoryFrontEndBlockFeatures, setup );
        features = [features; blockFeatures];
        
    end
    
    save( featuresSaveName, 'features', 'setup' );
else
    load( featuresSaveName, 'features' );
end

disp( ';' );
