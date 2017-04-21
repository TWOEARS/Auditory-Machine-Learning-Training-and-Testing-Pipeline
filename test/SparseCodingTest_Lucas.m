function SparseCodingTest_Lucas()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe(); %todo: anschauen; erzeugt wrapper


pipe.featureCreator = FeatureCreators.FeatureSet1Blockmean(); 
babyFemaleVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, ...
                                          'negOut', 'rest' ); 
pipe.labelCreator = babyFemaleVsRestLabeler;



pipe.modelCreator = ModelTrainers.SparseCodingTrainer( ... 
    'beta', 0.5, ...
    'num_bases', 100, ...
    'batch_size', 500, ...
    'num_iters', 30);
pipe.modelCreator.verbose( 'off' ); %Ausführung wird kommentiert (-verbose)


pipe.trainset = 'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TrainSet_1.flist';
% no testset needed here
pipe.testset = 'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TestSet_1.flist';

%pipe.trainset = 'C:\Users\Lucas\Documents\Masterarbeit\myGit\Code\FreesoundDownloader\data\mix_training\data.flist';
%pipe.testset = 'C:\Users\Lucas\Documents\Masterarbeit\myGit\Code\FreesoundDownloader\data\mix_test\data.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  ); %anechoic (HRIR) per default
pipe.init( sc, 'fs', 16000);

modelPath = pipe.pipeline.run( 'modelName', 'babyFemale_Lucas', 'modelPath', 'SparseCodingTest_Lucas', 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

