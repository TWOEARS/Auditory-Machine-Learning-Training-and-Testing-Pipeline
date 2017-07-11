function STLBaseSelectTest(varargin)

% parse input
p = inputParser;
addParameter(p,'scModelDir', '', @(x) ( ischar(x) && exist(x, 'dir') ) );

addParameter(p,'hpsMaxDataSize', 20000, @(x) mod(x,1) == 0 && x > 0 );
addParameter(p,'hpsBetas', [1], @(x)(isfloat(x) && isvector(x)) );

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
for i=1:length(files)
   file = files(i);
   data = load( fullfile(scModelDir,file.name) );
   scModels{i} = data.scModel;
end

% create hps grid
betaGrid = repmat(hpsBetas, length(scModels), 1);
betaGrid = num2cell(betaGrid(:));
modelGrid = repmat(scModels, length(hpsBetas), 1);
hpsSets = [modelGrid(:), betaGrid(:)];
hpsSets = cell2struct( hpsSets, {'scModel', 'scBeta'}, 2 );

save('HPS.mat', 'hpsSets', 'files');

% define training and test set for cross validation
trainSet = {'learned_models/IdentityKS/trainTestSets/IEEE_AASP_75pTrain_TrainSet_1.flist','learned_models/IdentityKS/trainTestSets/IEEE_AASP_75pTrain_TrainSet_2.flist'};
testSet = {'learned_models/IdentityKS/trainTestSets/IEEE_AASP_75pTrain_TestSet_1.flist','learned_models/IdentityKS/trainTestSets/IEEE_AASP_75pTrain_TestSet_2.flist'};

% hps over hpsSets
for hpsIndex=1:size(hpsSets,1)
    
    assert(length(trainSet) == length(testSet), ...
        'Lists of training and test sets must have same length');
    % cross validation over different training/test sets
    for cvIndex=1:length(trainSet)
        
        STLTest('scModel', hpsSets(hpsIndex).scModel, ...
                'scBeta', hpsSets(hpsIndex).scBeta, ...
                'trainSet', trainSet{cvIndex}, ...
                'testSet', testSet{cvIndex})
    end
end

