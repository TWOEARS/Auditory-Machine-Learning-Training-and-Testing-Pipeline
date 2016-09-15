function testNumSrc(modelNameIdent)

%% inits

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) );
startIdentificationTraining();
if nargin < 1
    modelNameIdent = '';
end
modelPath = 'numSrc';
modelName = [modelPath modelNameIdent];

%% setup pipeline for testing

pipe = TwoEarsIdTrainPipe();
% block creator
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.2 );
% feature creator
pipe.featureCreator = FeatureCreators.FeatureSetNSrcDetection();
% label creator
pipe.labelCreator = LabelCreators.NumberOfSourcesLabeler();
% model creator
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer(...
    [pwd filesep modelPath filesep modelName '-train.model.mat'],...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC );
pipe.modelCreator.verbose( 'on' );
% test set only for testing
pipe.testset = 'mini15_test.flist';
% setup data
pipe.setupData();

%% scene creation

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', 0 ) ) );
sc(1).addSource( SceneConfig.PointSource( ...
        'azimuth',SceneConfig.ValGen( 'manual', 90 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.testSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.PointSource( ...
        'azimuth',SceneConfig.ValGen( 'manual', -90 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.testSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
pipe.init( sc );

%% save model

savePath = pipe.pipeline.run(...
    'modelName', [modelName '-test'],...
    'modelPath', modelPath);

fprintf( ' -- Model test is saved at %s -- \n\n', savePath );

%% EOF

