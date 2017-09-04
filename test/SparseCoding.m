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

addParameter(p,'maxDataSize', 20000, ...
    @(x)(isinf(x) || (length(x) == 1 && rem(x,1) == 0 && x > 0) ) );

addParameter(p,'trainingSetPortion', 1, ...
    @(x)(isfloat(x) && length(x) == 1 && x > 0 && x <= 1) );

addParameter(p, 'addFileLists', {}, ...
    @(x) (iscell(x) && all(cellfun(@(y) ischar(y), x))));
% 
% {'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_1.flist', ...
%     'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_2.flist', ...
%     'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_3.flist', ...
%     'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_4.flist'}

parse(p, varargin{:});

% set input parameters
modelName           = p.Results.modelName;
modelPath           = p.Results.modelPath;
beta                = p.Results.beta;
num_bases           = p.Results.num_bases;
maxDataSize         = p.Results.maxDataSize;
trainingSetPortion  = p.Results.trainingSetPortion;
addFileLists        = p.Results.addFileLists;

if ~all(cellfun(@(y) ischar(y) && exist(db.getFile(y), 'file'), addFileLists))
   error('One or more of the entries in <addFileLists> are no valid flist files'); 
end

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

% -- prepare training data
% init FreesoundDownloader to fetch unlabeled data
fs = FreesoundDownloader();
% use files that are stored in specified directory without downloading new
% ones, we only need training data here 
% unlabeledList = fs.GetData('directory', '../../../reposX/twoears-data/sound_databases/Unlabeled/', 'useLocalFiles', true);

unlabeledList = 'learned_models/IdentityKS/trainTestSets/unlabeled.flist';

% add files if specified
if ~isempty(addFileLists)
    unlabeledFile = fopen(db.getFile(unlabeledList), 'a+');
    for idx=1:length(addFileLists)
        fin=fopen(db.getFile(addFileLists{idx}));
        tmp = fread(fin,'uint8');
        fprintf(unlabeledFile,'\n');
        fwrite(unlabeledFile, tmp,'uint8');
        fclose(fin);
    end
    fclose(unlabeledFile); 
end

if trainingSetPortion < 1
    pipe.trainset = ReduceFileList(db.getFile(unlabeledList), trainingSetPortion);
else 
    pipe.trainset = unlabeledList;
end

pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' )  )  );

% init and run pipeline
pipe.init( sc, 'fs', 16000);

modelPath = pipe.pipeline.run( 'modelName', modelName, 'modelPath', modelPath, 'debug', true);

fprintf( ' -- Model is saved at %s -- \n', modelPath );

