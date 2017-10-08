function savedModel = STLPureMethodWrapper(varargin)
%STLPureMethodWrapper Wrapper for any model trainer. Executes a pipeline 
%run performing a classification with a specified classifier. Having such a
%wrapper makes it easier to compare an STL classifier to different ones.

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

%% parse input
p = inputParser;
% file name of the computed model
addParameter(p,'modelName', '' ,@(x) ischar(x) );
% directory, where the computed model is saved
addParameter(p, 'modelPath', 'STLPureMethodWrapper', @(x) ischar(x));
% set of file lists for training (each entry will one fold in cross-validation)
addParameter(p,'trainSet', [], @(x) ischar(x) );
% set of file lists for testing (each entry will one fold in cross-validation)
addParameter(p,'testSet', [], @(x) ischar(x) );
% label creator that is used in pipeline
addParameter(p,'labelCreator', ...
    LabelCreators.MultiEventTypeLabeler( 'types', {{'alert'}}, 'negOut', 'rest' ) , ... 
    @(x) ( isa(x, 'LabelCreators.MultiEventTypeLabeler') ) );
% feature creator that is used in pipeline
addParameter(p,'featureCreator', FeatureCreators.FeatureSet5Blockmean() , ...
    @(x) ( isa(x, 'FeatureCreators.Base') ) );
% wrapped model trainer that is used in pipeline
addParameter(p,...
    'modelTrainer', ...
    ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99 ), ...
    @(x) ( isa(x, 'ModelTrainers.Base') ) );
% training is done on mixed sounds if this flag is true
addParameter(p, 'mixedSoundsTraining', false, @(x) islogical(x));
% testing is done on mixed sounds if this flag is true
addParameter(p, 'mixedSoundsTesting', false, @(x) islogical(x));

parse(p, varargin{:});

%% set parameter
modelName               = p.Results.modelName;
modelPath               = p.Results.modelPath;
trainSet                = p.Results.trainSet;
testSet                 = p.Results.testSet;
labelCreator            = p.Results.labelCreator;
featureCreator          = p.Results.featureCreator;
modelTrainer            = p.Results.modelTrainer;
mixedSoundsTraining     = p.Results.mixedSoundsTraining;
mixedSoundsTesting      = p.Results.mixedSoundsTesting;

%% warnings
if isempty(trainSet) && isempty(testSet)
    error('You have to pass at least one valid flist <trainSet> or <testSet> to STLPureMethodWrapper') 
end

if isempty(trainSet) && mixedSoundsTraining
    error('You have to pass a valid flist <trainSet> to STLPureMethodWrapper for mixed sound training') 
end

if isempty(testSet) && mixedSoundsTesting
    error('You have to pass a valid flist <testSet> to STLPureMethodWrapper for mixed sound testing') 
end

if isempty(modelName)
    modelName = sprintf('STLPureMethodWrapperModel_%s', datestr(now, 30));
end

if ~exist(modelPath, 'dir') && ~mkdir(modelPath)
    error(['The directory <modelPath> = < ' modelPath ' > does not '...
    'exist and can as well not be created, please specify another one.']); 
end

%% prepare pipeline run
pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = featureCreator;
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
                   pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
            'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
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

pipe.init( sc, 'fs', 16000);

modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath',...
    modelPath, 'debug', true);

savedModel = fullfile(modelPath, [modelName '.model.mat']);
fprintf( ' -- Model is saved at %s -- \n', modelPath ); 
end
