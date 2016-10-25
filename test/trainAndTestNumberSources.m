function trainAndTestNumberSources()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.2 );
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
% label will be number of active sources
noSrcsLabeler = LabelCreators.NumberOfSourcesLabeler();
pipe.labelCreator = noSrcsLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC, ...
    'family', 'multinomial', ... % deal with NumberOfSources as a multiclass label
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TrainSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', 'numSrcsModel', 'modelPath', 'numSrcs' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

%% test

pipe = TwoEarsIdTrainPipe();
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.2 );
pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean();
% label will be number of active sources
noSrcsLabeler = LabelCreators.NumberOfSourcesLabeler();
pipe.labelCreator = noSrcsLabeler;
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( ...
    [pwd filesep 'numSrcs/numSrcsModel.model.mat'], ...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC );
pipe.modelCreator.verbose( 'on' );

pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TestSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.testSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.testSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
pipe.init( sc );

modelPath = pipe.pipeline.run( 'modelName', 'numSrcsModel', 'modelPath', 'numSrcs' );

fprintf( ' -- Model test is saved at %s -- \n\n', modelPath );

