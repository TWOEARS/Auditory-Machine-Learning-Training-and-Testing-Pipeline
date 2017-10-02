function SparseCoding(varargin)

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

%% parse input
p = inputParser;
addParameter(p,'modelName', '' ,@(x) ischar(x) );

addParameter(p, 'modelPath', 'SparseCoding', @(x) ischar(x));

addParameter(p,'beta', 0.4, @(x)(isfloat(x) && isvector(x)) );

addParameter(p,'num_bases', 100, ...
    @(x)(length(x) == 1 && rem(x,1) == 0 && x > 0) );

addParameter(p,'num_iters', 20, @(x)(length(x) == 1 && rem(x,1) == 0 && x > 0));

addParameter(p,'maxDataSize', inf, ...
    @(x)(isinf(x) || (length(x) == 1 && rem(x,1) == 0 && x > 0) ) );

addParameter(p,'trainingSetPortion', 1, ...
    @(x)(isfloat(x) && length(x) == 1 && x > 0 && x <= 1) );

addParameter(p, 'trainSet', ...
    ['learned_models/IdentityKS/trainTestSets/' ...
    'unlabeled_freesound.flist'], ...
    @(x) ~isempty(x) && ischar(x) && exist(db.getFile(x), 'file') );

addParameter(p, 'mixedSoundsTraining', false, @(x) length(x) == 1 && islogical(x));

parse(p, varargin{:});

%% set parameters
modelName           = p.Results.modelName;
modelPath           = p.Results.modelPath;
beta                = p.Results.beta;
num_bases           = p.Results.num_bases;
num_iters           = p.Results.num_iters;
maxDataSize         = p.Results.maxDataSize;
trainingSetPortion  = p.Results.trainingSetPortion;
trainSet            = p.Results.trainSet;
mixedSoundsTraining = p.Results.mixedSoundsTraining;

%% warnings
if isempty(modelName)
    modelName = sprintf('scModel_b%d_beta%g_size%d_portion%g', ...
        num_bases, beta, maxDataSize, trainingSetPortion);
    if mixedSoundsTraining
        modelName = sprintf('%s_mixed', modelName);
    end
end

%% prepare pipeline run
pipe = TwoEarsIdTrainPipe();

pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean(); 

% set label creator to target any class, since data is unlabeled
pipe.labelCreator = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, ...
                                          'negOut', 'rest' ); 

pipe.modelCreator = ModelTrainers.SparseCodingTrainer( ... 
    'beta', beta, ...
    'num_bases', num_bases, ...
    'num_iters', num_iters, ...
    'maxDataSize', maxDataSize, ...
    'saveModelDir', modelPath);

% set training data, no test data required due to Sparse Coding
if trainingSetPortion < 1
    pipe.trainset = ReduceFileList(db.getFile(trainSet), trainingSetPortion);
else 
    pipe.trainset = trainSet;
end

pipe.setupData();

%% scene config (mixed or clean sounds)
if mixedSoundsTraining
    % mixed sounds in training
    sc = SceneConfig.SceneConfiguration();
    sc.addSource( SceneConfig.PointSource( ...
            'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
    sc.addSource( SceneConfig.PointSource( ...
            'data', SceneConfig.FileListValGen( ...
                   pipe.pipeline.trainSet(:,'fileName') ) ),...
            'snr', SceneConfig.ValGen( 'manual', 0 ),...
            'loop', 'randomSeq' );
    sc.setLengthRef( 'source', 1, 'min', 30 ); 
else
    % clean sounds in training
    sc = SceneConfig.SceneConfiguration();
    sc.addSource( SceneConfig.PointSource( ...
            'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );
end

%% init and run pipeline
pipe.init( sc, 'fs', 16000);
modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath', modelPath, 'debug', true);
fprintf( ' -- Model is saved at %s -- \n', modelPath );

