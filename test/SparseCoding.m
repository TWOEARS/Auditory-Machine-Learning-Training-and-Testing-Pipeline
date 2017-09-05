function SparseCoding(varargin)

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

% parse input
p = inputParser;
addParameter(p,'modelName', '' ,@(x) ischar(x) );

addParameter(p, 'modelPath', 'SparseCoding', @(x) ischar(x));

addParameter(p,'beta', 0.4, @(x)(isfloat(x) && isvector(x)) );

addParameter(p,'num_bases', 100, ...
    @(x)(length(x) == 1 && rem(x,1) == 0 && x > 0) );

addParameter(p,'maxDataSize', inf, ...
    @(x)(isinf(x) || (length(x) == 1 && rem(x,1) == 0 && x > 0) ) );

addParameter(p,'trainingSetPortion', 1, ...
    @(x)(isfloat(x) && length(x) == 1 && x > 0 && x <= 1) );

addParameter(p, 'trainSet', ...
    ['learned_models/IdentityKS/trainTestSets/' ...
    'unlabeled_freesound.flist'], ...
    @(x) ~isempty(x) && ischar(x) && exist(db.getFile(x), 'file') );

parse(p, varargin{:});

% set input parameters
modelName           = p.Results.modelName;
modelPath           = p.Results.modelPath;
beta                = p.Results.beta;
num_bases           = p.Results.num_bases;
maxDataSize         = p.Results.maxDataSize;
trainingSetPortion  = p.Results.trainingSetPortion;
trainSet            = p.Results.trainSet;

if isempty(modelName)
    modelName = sprintf('scModel_b%d_beta%g_size%d_portion%g', ...
        num_bases, beta, maxDataSize, trainingSetPortion);
end

% prepare pipe run
pipe = TwoEarsIdTrainPipe();

% -- feature creator
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean(); 

% -- label creator (any class, since data unlabeled)
babyFemaleVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, ...
                                          'negOut', 'rest' ); 
pipe.labelCreator = babyFemaleVsRestLabeler; 

% -- model creator
pipe.modelCreator = ModelTrainers.SparseCodingTrainer( ... 
    'beta', beta, ...
    'num_bases', num_bases, ...
    'maxDataSize', maxDataSize, ...
    'saveModelDir', modelPath);

pipe.modelCreator.verbose( 'off' ); % no console output

% -- set training data (no test data required)
if trainingSetPortion < 1
    pipe.trainset = ReduceFileList(db.getFile(trainSet), trainingSetPortion);
else 
    pipe.trainset = trainSet;
end

pipe.setupData();

% -- scene config (clean sounds)
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );

% init and run pipeline
pipe.init( sc, 'fs', 16000);

modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath', modelPath, 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

