function [xScaled, featureTranslators, featureFactors] = scaleTrainingData( x )

% translate data to 0 mean
featureTranslators = mean( x );

% transform data to 1 std
featureFactors = 1 ./ std( x );

xScaled = scaleData( x, featureTranslators, featureFactors );
