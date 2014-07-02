function features = makeFeaturesFromWp2Blocks( wp2Data, niState )
 
nBlocks = size( wp2Data, 1 );
for blockIdx = 1:nBlocks 
    fprintf( '.' );
    blockFeatures = niState.featureCreation.function( niState.featureCreation.functionParam, wp2Data(blockIdx,:) );
    if blockIdx == 1
        lenFeatureVector = length( blockFeatures );
        features = zeros( nBlocks, lenFeatureVector );
    end
    features(blockIdx,:) = blockFeatures;
end

