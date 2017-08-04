function savedModel = STLTest(varargin)

% parse input
p = inputParser;
addParameter(p,'scModel', [] ,@(x) ( isa(x, 'Models.SparseCodingModel') ) );

addParameter(p,'scModelBeta', -1 ,@(x) (  length(x) == 1 && x > 0 && isfloat(x) ) );

addParameter(p,'scBeta', 0.6, @(x)( length(x) == 1 && x > 0 && isfloat(x)));

addParameter(p,'trainSet', '', @(x) ( ischar(x) ) );

addParameter(p,'testSet', '', @(x) ( ischar(x) ) );

addParameter(p,'labelCreator', ...
    LabelCreators.MultiEventTypeLabeler( 'types', {{'alarm'}}, 'negOut', 'rest' ) , ... 
    @(x) ( isa(x, @LabelCreators.MultiEventTypeLabeler) ) );

addParameter(p,'featureCreator', FeatureCreators.FeatureSet5Blockmean() , ...
    @(x) ( isa(x, @FeatureCreators.Base) ) );

addParameter(p,...
    'modelTrainer', ...
    ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 ), ...
    @(x) ( isa(x, @ModelTrainers.Base) ) );

parse(p, varargin{:});

% set parameter
scModel                 = p.Results.scModel;
scModelBeta             = p.Results.scModelBeta;
scBeta                  = p.Results.scBeta;
trainSet                = p.Results.trainSet;
testSet                 = p.Results.testSet;
labelCreator            = p.Results.labelCreator;
wrappedFeatureCreator   = p.Results.featureCreator;
modelTrainer            = p.Results.modelTrainer;

if isempty(scModel) || isempty(trainSet)
   error('You have to pass a valid <scModel> and a valid flist <trainingSet> to STLTest') 
end

% prepare pipeline run
addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();

% -- feature creator
pipe.featureCreator = FeatureCreators.FeatureSetDecoratorSparseCoding(wrappedFeatureCreator, scModel, scBeta); 

% -- label creator
pipe.labelCreator = labelCreator; 

% -- model creator
pipe.modelCreator = modelTrainer;

pipe.modelCreator.verbose( 'on' );

% -- prepare data
pipe.trainset = trainSet;
pipe.testset  = testSet;

pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );

% init and run pipeline
pipe.init( sc, 'fs', 16000);


modelName = sprintf('STLTest_b%d_beta%g_new%g_%s', size(scModel.B,1), scModelBeta ,scBeta, datestr(now, 30));

modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath', 'STLTest', 'debug', true);

savedModel = fullfile(modelPath, [modelName '.model.mat']);
fprintf( ' -- Model is saved at %s -- \n', modelPath );


