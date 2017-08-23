function SparseCodingTest()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

beta = 0.4;
num_bases = 100;
maxDataSize = 50000;

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
    'beta', beta, ...
    'num_bases', num_bases, ...
    'maxDataSize', maxDataSize, ...
    'saveModelDir', './sc_100_0.4_50000');

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
modelName = sprintf('scModel_b%d_beta%g_size%d', num_bases, beta, maxDataSize);
modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath', 'SparseCoding', 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

