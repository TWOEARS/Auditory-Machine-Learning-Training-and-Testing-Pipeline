function [mask,featureDescription] = testGenFeatureMask()

pipe = TwoEarsIdTrainPipe( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 1.0, 0.2 );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
pipe.labelCreator = LabelCreators.MultiEventTypeLabeler(); % irrelevant

featuresToBeMasked = {'1.delta','2.delta'};

[mask,featureDescription] = genFeatureMask( pipe, featuresToBeMasked );

features2text( featureDescription, mask );

end
