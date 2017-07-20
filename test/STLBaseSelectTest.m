function STLBaseSelectTest(varargin)

% parse input
p = inputParser;
addParameter(p,'scModelDir', './Results_A/scSelect/', @(x) ( ischar(x) && exist(x, 'dir') ) );

addParameter(p,'hpsMaxDataSize', 20000, @(x) mod(x,1) == 0 && x > 0 );
addParameter(p,'hpsBetas', [0.4 0.6], @(x)(isfloat(x) && isvector(x)) );

parse(p, varargin{:});

% set parameters
scModelDir      = p.Results.scModelDir;
hpsMaxDataSize  = p.Results.hpsMaxDataSize;
hpsBetas        = p.Results.hpsBetas;

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
betaGrid = repmat(hpsBetas, length(scModels), 1);

modelGrid = repmat(scModels, length(hpsBetas), 1);
m = [modelGrid{:}];

infoGrid = repmat(scModelInfo, length(hpsBetas), 1);
i = [infoGrid{:}];
hpsSets =  {m(:), betaGrid(:), i(:)};
hpsSets = cell2struct( hpsSets, {'scModel', 'scBeta', 'scModelInfo'}, 2 );

% define training and test set for cross validation

%trainSet = {'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TrainSet_1.flist'};
%testSet = {'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TestSet_1.flist'};
        
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
    
% hps over hpsSets
for hpsIndex=1:size(hpsSets.scModel,1)
    % cross validation over different training/test sets
    for cvIndex=1:length(trainSet) 
        savedModel = STLTest('scModel', hpsSets.scModel(hpsIndex), ...
                    'scModelBeta', hpsSets.scModelInfo(hpsIndex).beta, ...
                    'scBeta', hpsSets.scBeta(hpsIndex), ...
                    'trainSet', trainSet{cvIndex}, ...
                    'testSet', testSet{cvIndex});
        data = load(savedModel);
        hpsSets.performance(hpsIndex, cvIndex) = data.testPerfresults.performance;
    end
end

save(sprintf('STLTest/HPSResults_%s.mat', datestr(now, 30)), 'hpsSets');


