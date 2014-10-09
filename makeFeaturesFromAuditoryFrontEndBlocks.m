function features = makeFeaturesFromAuditoryFrontEndBlocks( data, setup )
 
nBlocks = size( data, 2 );
for blockIdx = 1:nBlocks 
    fprintf( '.' );
    blockFeatures = setup.featureCreation.function( setup.featureCreation.functionParam, data(:,blockIdx) );
    if blockIdx == 1
        lenFeatureVector = length( blockFeatures );
        features = zeros( nBlocks, lenFeatureVector );
    end
    features(blockIdx,:) = blockFeatures;
end

