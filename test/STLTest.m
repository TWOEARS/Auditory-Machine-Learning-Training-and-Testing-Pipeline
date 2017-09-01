function savedModel = STLTest(varargin)

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

% parse input
p = inputParser;
addParameter(p,'scModel', [] ,@(x) ( isa(x, 'Models.SparseCodingModel') ) );

addParameter(p,'modelName', '' ,@(x) ischar(x) );

addParameter(p, 'modelPath', 'STLTest', @(x) ischar(x));

addParameter(p,'scGamma', 0.4, @(x)( length(x) == 1 && x > 0 && isfloat(x)));

addParameter(p,'trainSet', '', @(x) ischar(x) );

addParameter(p,'testSet', '', @(x) ischar(x) );

addParameter(p,'labelCreator', ...
    LabelCreators.MultiEventTypeLabeler( 'types', {{'alert'}}, 'negOut', 'rest' ) , ... 
    @(x) ( isa(x, 'LabelCreators.MultiEventTypeLabeler') ) );

addParameter(p,'featureCreator', FeatureCreators.FeatureSet5Blockmean() , ...
    @(x) ( isa(x, 'FeatureCreators.Base') ) );

addParameter(p,...
    'modelTrainer', ...
    ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 ), ...
    @(x) ( isa(x, 'ModelTrainers.Base') ) );

parse(p, varargin{:});

% set parameters
scModel                 = p.Results.scModel;
modelName               = p.Results.modelName;
modelPath               = p.Results.modelPath;
scGamma                 = p.Results.scGamma;
trainSet                = p.Results.trainSet;
testSet                 = p.Results.testSet;
labelCreator            = p.Results.labelCreator;
wrappedFeatureCreator   = p.Results.featureCreator;
modelTrainer            = p.Results.modelTrainer;

if isempty(scModel) || isempty(trainSet)
   error('You have to pass a valid <scModel> and a valid flist <trainingSet> to STLTest') 
end

if isempty(modelName)
    modelName = sprintf('STLModel_b%d_gamma%g_%s',size(scModel.B,1), scGamma, datestr(now, 30));
end

if ~exist(modelPath, 'dir') && ~mkdir(modelPath)
    error(['The directory <modelPath> = < ' modelPath ' > does not '...
    'exist and can as well not be created, please specify another one.']); 
end
    
    
% prepare pipeline run
addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();

% -- feature creator
pipe.featureCreator = FeatureCreators.FeatureSetDecoratorSparseCoding(wrappedFeatureCreator, scModel, scGamma); 

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

modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath', modelPath, 'debug', true);

savedModel = fullfile(modelPath, [modelName '.model.mat']);
fprintf( ' -- Model is saved at %s -- \n', modelPath );


