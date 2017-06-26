function STLBaseSelectTest()

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

pipe = TwoEarsIdTrainPipe();

% -- feature creator
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean(); 

% -- label creator 
babyFemaleVsRestLabeler = ... 
    LabelCreators.MultiEventTypeLabeler( 'types', {{'speech'}}, ...
                                          'negOut', 'rest' ); 
pipe.labelCreator = babyFemaleVsRestLabeler; 

% extract bases
path = './Results CV Sparse Coding/1st attempt/';
files = dir(sprintf('%ssc_*.mat', path));
bases = cell(length(files), 1);
for i=1:length(files)
   file = files(i);
   data = load(sprintf('%s%s',path,file.name));
   % transpose B, because base vectors are stored columnwise
   bases{i} = data.B';
end

% get model for scalingFactors (otherwise bases may scale badly and the effect is gone)
data = load('./Results CV Sparse Coding/1st attempt/SparseCodingSelectTest_datasize5000_170531102828.model.mat');
scalingModel = data.model.model; 

% -- model creator
pipe.modelCreator = ModelTrainers.STLBaseSelectTrainer( ...
    'hpsBases', bases, ...    % sparse bases for STL
    'hpsBetaRange', [0.4 1], ... % beta range
    'scalingModel', scalingModel, ... % is needed for scalings of training and test data
    'hpsRefineStages', 0, ...    % number of iterative hps refinement stages
    'hpsSearchBudget', 4, ...    % number of hps grid search parameter values per dimension
    'hpsCvFolds', 2);            % number of hps cv folds of training set

pipe.modelCreator.verbose( 'off' ); % no console output

% define train and test set
pipe.trainset = 'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TrainSet_1.flist';
pipe.testset = 'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );

% init and run pipeline
pipe.init( sc, 'fs', 16000);
modelPath = pipe.pipeline.run( 'modelName', 'SparseCodingSelectTest_Lucas', 'modelPath', 'SparseCodingTest_Lucas', 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

