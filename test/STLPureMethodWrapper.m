function savedModel = STLPureMethodWrapper(varargin)

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

% parse input
p = inputParser;
addParameter(p,'modelName', '' ,@(x) ischar(x) );

addParameter(p, 'modelPath', 'STLPureMethodWrapper', @(x) ischar(x));

addParameter(p,'trainSet', '', @(x) ischar(x) );

addParameter(p,'testSet', '', @(x) ischar(x) );

addParameter(p,'labelCreator', ...
    LabelCreators.MultiEventTypeLabeler( 'types', {{'alarm'}}, 'negOut', 'rest' ) , ... 
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

% set parameter
modelName               = p.Results.modelName;
modelPath               = p.Results.modelPath;
trainSet                = p.Results.trainSet;
testSet                 = p.Results.testSet;
labelCreator            = p.Results.labelCreator;
featureCreator          = p.Results.featureCreator;
modelTrainer            = p.Results.modelTrainer;

if isempty(trainSet)
   error(['You have to pass a valid flist <trainingSet> to '...
       'STLPureMethodWrapper']); 
end

if isempty(modelName)
    modelName = sprintf('STLPureMethodWrapperModel_%s', datestr(now, 30));
end

if ~exist(modelPath, 'dir') && ~mkdir(modelPath)
    error(['The directory <modelPath> = < ' modelPath ' > does not '...
    'exist and can as well not be created, please specify another one.']); 
end

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreator;
pipe.labelCreator = labelCreator;
pipe.modelCreator = modelTrainer;

pipe.trainset = trainSet;
pipe.testset = testSet;
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )));

pipe.init( sc, 'fs', 16000);

modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath',...
    modelPath, 'debug', true);

savedModel = fullfile(modelPath, [modelName '.model.mat']);
fprintf( ' -- Model is saved at %s -- \n', modelPath ); 
end
