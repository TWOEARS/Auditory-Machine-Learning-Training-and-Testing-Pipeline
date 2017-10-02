function savedModel = STL(varargin)

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

%% parse input
p = inputParser;
addParameter(p,'scModel', [] ,@(x) ( isa(x, 'Models.SparseCodingModel') ) );

addParameter(p,'modelName', '' ,@(x) ischar(x) );

addParameter(p, 'modelPath', 'STL', @(x) ischar(x));

addParameter(p,'scGamma', 0.4, @(x)( length(x) == 1 && x > 0 && isfloat(x)));

addParameter(p,'trainSet', [], @(x) ischar(x) );

addParameter(p,'testSet', [], @(x) ischar(x) );

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

addParameter(p, 'mixedSoundsTraining', false, @(x) islogical(x));

addParameter(p, 'mixedSoundsTesting', false, @(x) islogical(x));

parse(p, varargin{:});

%% set parameters
scModel                 = p.Results.scModel;
modelName               = p.Results.modelName;
modelPath               = p.Results.modelPath;
scGamma                 = p.Results.scGamma;
trainSet                = p.Results.trainSet;
testSet                 = p.Results.testSet;
labelCreator            = p.Results.labelCreator;
wrappedFeatureCreator   = p.Results.featureCreator;
modelTrainer            = p.Results.modelTrainer;
mixedSoundsTraining     = p.Results.mixedSoundsTraining;
mixedSoundsTesting      = p.Results.mixedSoundsTesting;

%% warnings
if isempty(scModel)
   error('You have to pass a valid <scModel> to STL') 
end

if isempty(trainSet) && isempty(testSet)
    error('You have to pass at least one valid flist <trainSet> or <testSet> to STL') 
end

if isempty(trainSet) && mixedSoundsTraining
    error('You have to pass a valid flist <trainSet> to STL for mixed sound training') 
end

if isempty(testSet) && mixedSoundsTesting
    error('You have to pass a valid flist <testSet> to STL for mixed sound testing') 
end

if isempty(modelName)
    modelName = sprintf('STLModel_b%d_gamma%g_%s',size(scModel.B,1), scGamma, datestr(now, 30));
end

if ~exist(modelPath, 'dir') && ~mkdir(modelPath)
    error(['The directory <modelPath> = < ' modelPath ' > does not '...
    'exist and can as well not be created, please specify another one.']); 
end

%% prepare pipeline run
pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = FeatureCreators.FeatureSetDecoratorSparseCoding(wrappedFeatureCreator, scModel, scGamma); 
pipe.labelCreator = labelCreator; 
pipe.modelCreator = modelTrainer;
if ~isempty(trainSet) 
    pipe.trainset = trainSet; 
end
if ~isempty(testSet) 
    pipe.testset  = testSet; 
end
pipe.setupData();

%% scene configuration (mixed or clean sounds)
if mixedSoundsTraining
    % mixed sounds in training
    sc = SceneConfig.SceneConfiguration();
    sc.addSource( SceneConfig.PointSource( ...
            'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
    sc.addSource( SceneConfig.PointSource( ...
            'data', SceneConfig.FileListValGen( ...
                   pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ) ),...
            'snr', SceneConfig.ValGen( 'manual', 0 ),...
            'loop', 'randomSeq' );
    sc.setLengthRef( 'source', 1, 'min', 30 ); 
else
    if mixedSoundsTesting
        % mixed sounds in testing
        sc = SceneConfig.SceneConfiguration();
        sc.addSource( SceneConfig.PointSource( ...
                'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
        sc.addSource( SceneConfig.PointSource( ...
                'data', SceneConfig.FileListValGen( ...
                       pipe.pipeline.testSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
                'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
                'snr', SceneConfig.ValGen( 'manual', 0 ),...
                'loop', 'randomSeq' );
        sc.setLengthRef( 'source', 1, 'min', 30 );
    else
        % clean sound
        sc = SceneConfig.SceneConfiguration();
        sc.addSource( SceneConfig.PointSource( ...
                'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
    end
end
%% init and run pipeline
pipe.init( sc);
modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath', modelPath, 'debug', true);
savedModel = fullfile(modelPath, [modelName '.model.mat']); % for output
fprintf( ' -- Model is saved at %s -- \n', modelPath );


