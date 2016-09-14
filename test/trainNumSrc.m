function trainNumSrc(modelNameIdent)

%% inits

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) );
startIdentificationTraining();
if nargin < 1
    modelNameIdent = '';
end
modelPath = 'numSrc';
modelName = [modelPath modelNameIdent];

%% setup pipeline for training

pipe = TwoEarsIdTrainPipe();
% block creator
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 0.2 );
% feature creator
pipe.featureCreator = FeatureCreators.FeatureSetNSrcDetection();
% label creator
pipe.labelCreator = LabelCreators.NumberOfSourcesLabeler();
% model creator GLMNET
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.MultinomialBAC, ...
    'family', 'multinomial', ...
    'cvFolds', 2, ...
    'alpha', 0.99 );
% model creator LibSVM
% pipe.modelCreator = ModelTrainers.SVMmodelSelectTrainer( ...
%     'performanceMeasure', @PerformanceMeasures.MultinomialBAC, ...
%     'hpsEpsilons', [0.001], ... % define hps set (not a range)
%     'hpsKernels', [0], ...      % define hps set (not a range). 0 = linear, 2 = rbf
%     'hpsCrange', [-6 2], ...    % define hps C range -- logspaced between 10^a and 10^b
%     'hpsGammaRange', [-12 3], ... % define hps Gamma range -- logspaced between 10^a and 
%                               ... % 10^b. Ignored for kernel other than rbf
%     'hpsMaxDataSize', 1000, ...  % max data set size to use in hps (number of samples)
%     'hpsRefineStages', 1, ...   % number of iterative hps refinement stages
%     'hpsSearchBudget', 7, ...   % number of hps grid search parameter values per dimension
%     'hpsCvFolds', 4,...         % number of hps cv folds of training set
%     'finalMaxDataSize',10000);
pipe.modelCreator.verbose( 'on' );
% train set only for training
pipe.trainset = 'mini30_train.flist';
% setup data
pipe.setupData();

%% scene creation

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ),...
        'azimuth', SceneConfig.ValGen( 'manual', 0 ) ) );
sc(1).addSource( SceneConfig.PointSource( ...
        'azimuth',SceneConfig.ValGen( 'manual', 90 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.trainSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.PointSource( ...
        'azimuth',SceneConfig.ValGen( 'manual', -90 ),...
        'data', SceneConfig.FileListValGen( pipe.pipeline.trainSet(:,'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ) ),...
        'loop', 'randomSeq' );
pipe.init( sc );

%% save model

savePath = pipe.pipeline.run(...
    'modelName', [modelName '-train'],...
    'modelPath', modelPath);

fprintf( ' -- Model is saved at %s -- \n\n', savePath );

%% EOF
