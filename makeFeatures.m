function [features] = makeFeatures( soundsDir, className, niState )

fprintf( 'make features' );

[classSoundFileNames, soundFileNames] = makeSoundLists( soundsDir, className );

featuresSavePreStr = [soundsDir '/' getFeaturesHash( niState )];
featuresSaveName = [featuresSavePreStr '.features.mat'];
if ~exist( featuresSaveName, 'file' )
    
    features = [];
    for i = 1:length( soundFileNames )
        
        fprintf( '.' );
        
        blocksSaveName = [soundFileNames{i} '.' getBlockDataHash( niState ) '.blocks.mat'];
        ls = load( blocksSaveName, 'wp2BlockFeatures' );
        wp2BlockFeatures = ls.wp2BlockFeatures;
        
        blockFeatures = makeFeaturesFromWp2Blocks( wp2BlockFeatures, niState );
        features = [features; blockFeatures];
        
    end
    
    save( featuresSaveName, 'features', 'niState' );
else
    load( featuresSaveName, 'features' );
end

disp( ';' );
