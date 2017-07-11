function SparseCodingTest()

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
pipe.modelCreator = ModelTrainers.SparseCodingTrainer( ... 
    'beta', 1, ...
    'num_bases', 50, ...
    'num_iters', 20, ...
    'maxDataSize', 20000, ...
    'saveModelDir', './scSelect');

pipe.modelCreator.verbose( 'off' ); % no console output

% -- prepare training data
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
modelPath = pipe.pipeline.run( 'modelName', 'SparseCodingTest', 'modelPath', 'SparseCodingSelectTest_Lucas', 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

