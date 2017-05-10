function SparseCodingTest_Lucas()

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
    'hpsSearchBudget', 2, ...   % number of hps grid search parameter values per dimension
    'hpsCvFolds', 3 ...         % number of hps cv folds of training set
 );

% pipe.modelCreator = ModelTrainers.SparseCodingTrainer( ... 
%     'beta', 0.6, ...
%     'num_bases', 200, ...
%     'batch_size', 4000, ...
%     'num_iters', 30);

pipe.modelCreator.verbose( 'off' ); % no console output

% -- prepare training data
% init FreesoundDownloader to fetch unlabeled data
fs = FreesoundDownloader();
% use files that are stored in specified directory without downloading new
% ones, we only need training data here 
pipe.trainset = fs.GetData('directory', '..\..\binaural-simulator\tmp\sound_databases\Unlabeled\', 'useLocalFiles', true);
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );

% init and run pipeline
pipe.init( sc, 'fs', 16000);
modelPath = pipe.pipeline.run( 'modelName', 'SparseCodingTest_Lucas', 'modelPath', 'SparseCodingTest_Lucas', 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

