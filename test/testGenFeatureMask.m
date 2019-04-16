function [mask,featureDescription] = testGenFeatureMask()

pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 1.0, 0.2 );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
pipe.labelCreator = LabelCreators.MultiEventTypeLabeler(); % irrelevant

featuresToBeMasked = {'ratemap'};

[mask,featureDescription] = genFeatureMask( pipe, featuresToBeMasked );

end
