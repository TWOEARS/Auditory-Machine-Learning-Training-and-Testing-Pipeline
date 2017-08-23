function STLBaseSelect(varargin)

% parse input
p = inputParser;
addParameter(p,'scModelDir', './Results_A/selectedModels/', @(x) ( ischar(x) && exist(x, 'dir') ) );

addParameter(p,'hpsMaxDataSize', Inf, @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
addParameter(p,'hpsGammas', [0.4 0.6], @(x)(isfloat(x) && isvector(x)) );

addParameter(p,'label', 'alarm', @(x)ischar(x) );

parse(p, varargin{:});

% set parameters
scModelDir      = p.Results.scModelDir;
hpsMaxDataSize  = p.Results.hpsMaxDataSize;
hpsGammas        = p.Results.hpsGammas;
label           = p.Results.label;

if isempty(scModelDir)
    error('You have to pass a valid directory <scModelDir> to STLBaseSelectTest')
end

% extract bases
files = dir( fullfile(scModelDir,'scModel_*.mat') );
scModels = cell(length(files), 1);
scModelInfo = cell(length(files), 1);
for i=1:length(files)
   file = files(i);
   % extract model information from file name
   splitted = strsplit(file.name, '_');
   scModelInfo{i}.base = str2double(splitted{2}(2:end));
   scModelInfo{i}.beta = str2double(splitted{3}(5:end));
   % extract scModel with base
   data = load( fullfile(scModelDir,file.name) );
   scModels{i} = data.scModel;
end

% create hps grid
gammaGrid = repmat(hpsGammas, length(scModels), 1);

modelGrid = repmat(scModels, length(hpsGammas), 1);
m = [modelGrid{:}];

infoGrid = repmat(scModelInfo, length(hpsGammas), 1);
i = [infoGrid{:}];
hpsSets =  {m(:), gammaGrid(:), i(:)};
hpsSets = cell2struct( hpsSets, {'scModel', 'scGamma', 'scModelInfo'}, 2 );

% define training and test set for cross validation

% trainSet = {'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TrainSet_1.flist'};
% testSet = {'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TestSet_1.flist'};
        
trainSet = {'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_1.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_2.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_3.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_4.flist'};
        
testSet = {'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_1.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_2.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_3.flist', ...
            'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_4.flist'};


assert(length(trainSet) == length(testSet), ...
        'Lists of training and test sets must have same length');

labelCreator = LabelCreators.MultiEventTypeLabeler( 'types', {label}, 'negOut', 'rest' );

modelTrainer = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99, ...
    'maxDataSize', hpsMaxDataSize);

% hps over hpsSets
for hpsIndex=1:size(hpsSets.scModel,1)
    % cross validation over different training/test sets
    for cvIndex=1:length(trainSet)
        
        modelName = sprintf('scModel_b%d_beta%g_gamma%g_%s', ...
            hpsSets.scModelInfo(hpsIndex).base,...
            hpsSets.scModelInfo(hpsIndex).beta,...
            hpsSets.scGamma(hpsIndex),...
            datestr(now, 30) );
        
        STLTest('scModel', hpsSets.scModel(hpsIndex), ...
                    'modelName', modelName, ...
                    'scGamma', hpsSets.scGamma(hpsIndex), ...
                    'trainSet', trainSet{cvIndex}, ...
                    'testSet', testSet{cvIndex}, ...
                    'labelCreator', labelCreator, ...
                    'modelTrainer', modelTrainer);
    end
end


