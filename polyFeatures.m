function features = polyFeatures( param, rmBlock )

pdegree = 4;
nFreqChannels = size( rmBlock, 1 );
lenFeatureVector = nFreqChannels * (pdegree+1);
features = zeros( lenFeatureVector,1 );

% mean of left and right channel
lrMean = mean( rmBlock, 3 );

%fit a polynomial to every gammatone frequency channel, store coefficients in one vector
for i = 1:nFreqChannels
    features(i*pdegree+i-pdegree:i*(pdegree+1)) = polyfit( 1:size(lrMean,2), lrMean(i,:), pdegree );
end
