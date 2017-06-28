function SparseCodingSelectTest(varargin)

p = inputParser;

addParameter(p,'hpsMaxDataSize', 20000, @(x) mod(x,1) == 0 && x > 0 );
addParameter(p,'finalMaxDataSize', 20000, @(x) mod(x,1) == 0 && x > 0 );
addParameter(p,'hpsSearchBudget', 4 , @(x) mod(x,1) == 0 && x > 0 );
addParameter(p,'hpsBetas', [1], @(x)(isfloat(x) && isvector(x)) );
addParameter(p,'hpsNumBasesRange', [100 5000], @(x) ( all(mod(x,1) == 0) && length(x)==2 && x(1) < x(2) ) );
addParameter(p,'hpsCvFolds', 3, @(x) ( length(x) == 1 && x > 1 && mod(x,1) == 0 ) );

parse(p, varargin{:});

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();

% -- feature creator
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean(); 

% -- label creator (ignore, since data unlabeled ?)
babyFemaleVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, ...
                                          'negOut', 'rest' ); 
pipe.labelCreator = babyFemaleVsRestLabeler; 

% -- model creator

pipe.modelCreator = ModelTrainers.SparseCodingSelectTrainer( ...
    'hpsBetas', p.Results.hpsBetas, ... % betas
    'hpsNumBasesRange', p.Results.hpsNumBasesRange, ... % number of bases range
    'hpsMaxDataSize', p.Results.hpsMaxDataSize, ...  % max data set size to use in hps (number of samples)
    'hpsRefineStages', 0, ...   % number of iterative hps refinement stages
    'hpsSearchBudget', p.Results.hpsSearchBudget, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', p.Results.hpsCvFolds,...         % number of hps cv folds of training set
    'finalMaxDataSize', p.Results.finalMaxDataSize);

pipe.modelCreator.verbose( 'off' ); % no console output

% init FreesoundDownloader to fetch unlabeled data
fs = FreesoundDownloader();
% use files that are stored in specified directory without downloading new
% ones, we only need training data here 
pipe.trainset = fs.GetData('directory', '../../binaural-simulator/tmp/sound_databases/Unlabeled/', 'useLocalFiles', true);
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );

% init and run pipeline
pipe.init( sc, 'fs', 16000);
modelName = sprintf('SparseCodingSelect_datasize%d_%s', p.Results.hpsMaxDataSize, datestr(now,'yymmddHHMMSS'));
modelPath = pipe.pipeline.run( 'modelName', modelName , 'modelPath', 'SparseCodingSelectTest_Lucas', 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

