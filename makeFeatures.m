function [features] = makeFeatures( dfiles, soundsDir, esetup )

fprintf( 'make features' );

featuresSavePreStr = [soundsDir '/' getFeaturesHash( esetup )];
featuresSaveName = [featuresSavePreStr '.features.mat'];
if ~exist( featuresSaveName, 'file' )
    
    features = [];
    for i = 1:length( dfiles.soundFileNames )
        
        fprintf( '.' );
        
        blocksSaveName = [dfiles.soundFileNames{i} '.' getBlockDataHash( esetup ) '.blocks.mat'];
        ls = load( blocksSaveName, 'wp2BlockFeatures' );
        wp2BlockFeatures = ls.wp2BlockFeatures;
        
        blockFeatures = makeFeaturesFromWp2Blocks( wp2BlockFeatures, esetup );
        features = [features; blockFeatures];
        
    end
    
    save( featuresSaveName, 'features', 'esetup' );
else
    load( featuresSaveName, 'features' );
end

disp( ';' );
