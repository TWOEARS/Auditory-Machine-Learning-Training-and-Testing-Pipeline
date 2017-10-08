function SparseCodingModelComputation(varargin)
% SparseCodingModelComputation Computes multiple Sparse Coding models for
% different hyperparameters

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

%% parse input
p = inputParser;

% directory where all computed Sparse Coding models are saved at
addParameter(p, 'modelPath', fullfile(pwd, 'SparseCodingModelComputation'), @(x) ischar(x));
% maximum sample size for unlabeled data in Sparse Coding
addParameter(p,'maxDataSize', 20000, @(x) mod(x,1) == 0 && x > 0 );
% defines how many models of the same configuration are computed
addParameter(p,'configFactor', 1 , @(x) mod(x,1) == 0 && x > 0 );
% set of sparsity factors beta for Sparse Coding
addParameter(p,'betas', [0.4 0.6 0.8 1], @(x)(isfloat(x) && isvector(x)) );
% set of base dimensions that should be computed in Sparse Coding
addParameter(p,'bases', [100 368 1357], @(x) ( all(mod(x,1) == 0) && isvector(x) ) );
% training set (unlabeled data)
addParameter(p, 'trainSet', ...
    '/learned_models/IdentityKS/trainTestSets/unlabeled_freesound.flist', ...
    @(x) ~isempty(x) && ischar(x) && exist(db.getFile(x), 'file') );
% defines which portion of the training sound files should be used for
% training
addParameter(p, 'trainingSetPortions', 1, ...
    @(x) ( isfloat(x) && x <= 1 && x > 0 ) );
% trains on mixed sounds if flag is set to true
addParameter(p, 'mixedSoundsTraining', false, @(x) length(x) == 1 && islogical(x));
parse(p, varargin{:});

%% set parameters
modelPath           = p.Results.modelPath;
maxDataSize         = p.Results.maxDataSize;
configFactor        = p.Results.configFactor;
betas               = p.Results.betas;
bases               = p.Results.bases;
trainSet            = p.Results.trainSet;
trainingSetPortions = p.Results.trainingSetPortions;
mixedSoundsTraining = p.Results.mixedSoundsTraining;

%% compute Sparse Coding models for all combinations of hyperparameters
for configFactorIndex = 1:configFactor
    for baseIndex = 1:length(bases)
        for betaIndex = 1:length(betas)
            for portionIndex = 1:length(trainingSetPortions)
                
                modelName = sprintf('scModel_b%d_beta%g_size%d_portion%g_%d', ...
                    bases(baseIndex),...
                    betas(betaIndex), ...
                    maxDataSize, ...
                    trainingSetPortions(portionIndex), ...
                    configFactor);
                
                if mixedSoundsTraining
                    modelName = sprintf('%s_mixed', modelName);
                end
                
                SparseCoding( 'modelName', modelName, ...
                    'modelPath', modelPath, ...
                    'beta', betas(betaIndex), ...
                    'num_bases', bases(baseIndex), ...
                    'maxDataSize', maxDataSize, ...
                    'trainSet', trainSet, ...
                    'trainingSetPortion', trainingSetPortions(portionIndex), ...
                    'mixedSoundsTraining', mixedSoundsTraining );                
            end
        end
    end
end
