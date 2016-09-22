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
% blackboard system knowledge source wrapper for azimut distribution
pipe.ksWrapper = DataProcs.DnnLocKsWrapper(); % uses 0.5s blocksize
% block creator
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.5/3 );
% feature creator
pipe.featureCreator = FeatureCreators.FeatureSetNSrcDetectionPlusModelOutputs();
% label creator
pipe.labelCreator = LabelCreators.NumberOfSourcesLabeler( 'srcMinEnergy', -22 );

% model creator
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer(...
    [pwd filesep modelPath filesep modelName '-train.model.mat'],...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC );
pipe.modelCreator.verbose( 'on' );
% test set only for testing
pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_mini_TestSet_1.flist';
% pipe.testset = 'mini15_test.flist';
% setup data
pipe.setupData();

%% scene creation

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', 0 ) ) );
sc(1).addSource( SceneConfig.PointSource(...
        'azimuth',SceneConfig.ValGen( 'manual', 45 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.testSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.PointSource(...
        'azimuth',SceneConfig.ValGen( 'manual', -45 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.testSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.DiffuseSource(...
        'offset', SceneConfig.ValGen( 'manual', -1 ) ),...
        'loop', 'randomSeq',...
        'snr', SceneConfig.ValGen( 'manual', 0 ),...
        'snrRef', 1 );
pipe.init( sc, 'fs', 16000 );

%% save model

savePath = pipe.pipeline.run(...
    'modelName', [modelName '-test'],...
    'modelPath', modelPath);

fprintf( ' -- Model test is saved at %s -- \n\n', savePath );

%% EOF

