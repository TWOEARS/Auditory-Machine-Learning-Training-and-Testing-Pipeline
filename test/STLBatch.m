function STLBatch(varargin)
%STLBatch Does STL LASSO classification for multiple hyperparameter configs
    %
    %   This function can be used to apply the classification step of STL
    %   with LASSO using multiple hyperparameter configurations of STL
    %   for a given classification setting (train/test set, maxDataSize,
    %   target classes). The performances of the cross-validation 
    %   for each hyperparameter configuration are stored in a file 
    %   <resultsFile> to provide a kind of cache in case the script is
    %   interrupted. Another call of the function will attempt to continue
    %   with configurations that have not been computed yet.
    %
    %   It is important, that the Sparse Coding models have their
    %   configuration parameters encoded in their file name 
    %   with the following regular expression format 
    %   '_b[0-9]+_' for the number of bases and 
    %   '_beta[0-9]\.[0-9]' for sparsity factor beta 
    %   as those parameters are not contained in the model file.
    %
    %   A function use case would be a HPS search to compare the results of
    %   different STL configurations with respect to classification
    %   performance in different target classes.

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

%% parse input
p = inputParser;

% specifies the directory of the computed sparse coding models, that are
% required for STL classification 
addParameter(p,'scModelDir', './SparseCoding/selectedModels/', @(x) ( ischar(x) && exist(x, 'dir') ) );

% specifies where the computed STLModels should be saved
addParameter(p,'savePath', './STLBaseSelect', @(x) ( ischar(x) && exist(x, 'dir') ) );

% specifies the maximal number of samples for training the classifier
addParameter(p,'maxDataSize', Inf, @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );

% hps set for the sparsity factor that is used to extract high-level 
% features on the input features of the classifier (STL feature extraction)
addParameter(p,'gammas', [0.4 0.6], @(x)(isfloat(x) && isvector(x)) );

% set containing each target class for which classification performances
% should be computed
% {'alarm', 'baby', 'femaleSpeech', 'fire'}
addParameter(p,'labels', {'alert', 'speech'}, ...
   @(x)(iscell(x) && ~isempty(x)));

% resultsFile where performances are stored for caching or later evalutations 
addParameter(p, 'resultsFile', ...
    './STLBaseSelect/STLBaseSelect_results.mat', ...
    @(x) ischar(x) && exist(x, 'file'))

parse(p, varargin{:});

%% set parameters
scModelDir      = p.Results.scModelDir;
savePath        = p.Results.savePath; 
maxDataSize     = p.Results.maxDataSize;
gammas          = p.Results.gammas;
labels          = p.Results.labels;
resultsFile     = p.Results.resultsFile;

modelTrainer = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99, ...
    'maxDataSize', maxDataSize);

if isempty(scModelDir)
    error('You have to pass a valid directory <scModelDir> to STLBaseSelectTest')
end

%% extract information from sparse coding models
files = dir( fullfile(scModelDir,'scModel_*.mat') );
scModels = cell(length(files), 1);
scModelInfo = cell(length(files), 1);
for i=1:length(files)
   file = files(i);
   % extract model information from file name
   [startIdx, endIdx] = regexp(file.name, '_b[0-9]+_');
   scModelInfo{i}.base = str2double( file.name(startIdx+2:endIdx-1) );
   [startIdx, endIdx] = regexp(file.name, '_beta[0-9](\.[0-9])?');
   scModelInfo{i}.beta = str2double( file.name(startIdx+5:endIdx) );
   % extract scModel with base
   data = load( fullfile(scModelDir,file.name) );
   scModels{i} = data.scModel;
end

%% create hps grid
gammaGrid = repmat(gammas, length(scModels), 1);
modelGrid = repmat(scModels, length(gammas), 1);
m = [modelGrid{:}];
infoGrid = repmat(scModelInfo, length(gammas), 1);
i = [infoGrid{:}];
hpsSets =  {m(:), gammaGrid(:), i(:)};
hpsSets = cell2struct( hpsSets, {'scModel', 'gamma', 'scModelInfo'}, 2 );

%% define training and test set for cross validation
trainSet = {'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TrainSet_1.flist'};
testSet = {'learned_models\IdentityKS\trainTestSets\IEEE_AASP_75pTrain_TestSet_1.flist'};
        
% trainSet = {'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_1.flist', ...
%             'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_2.flist', ...
%             'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_3.flist', ...
%             'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TrainSet_4.flist'};
%         
% testSet = {'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_1.flist', ...
%             'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_2.flist', ...
%             'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_3.flist', ...
%             'learned_models/IdentityKS/trainTestSets/NIGENS160807_75pTrain_TestSet_4.flist'};

assert(length(trainSet) == length(testSet), ...
        'Lists of training and test sets must have same length');

%% init results
% try to load file with already computed configurations to skip computation 
% of those configurations, else initialise a new variable for the results
if exist(resultsFile, 'file')
    filedata = load(resultsFile);
    results = filedata.results;
else
    results = struct('label', {}, ...
        'base' , 0, ...
        'beta' , 0, ...
        'gamma', 0, ...
        'STLPerformance', []);
end
%% do hyperparameter search over all target classes
for labelIndex=1:length(labels)
    labelCreator = LabelCreators.MultiEventTypeLabeler(...
        'types', labels(labelIndex), 'negOut', 'rest' );
       
    % loop over all hyperparameters
    for hpsIndex=1:size(hpsSets.scModel,1)
        % cross validation over different training/test sets
        for cvIndex=1:length(trainSet)
            % check whether configuration is already entry in results
            entryIdx = find( cellfun(@(x) strcmp(x,labels{labelIndex}), ...
                {results.label}) & ...
                [results.base]  == hpsSets.scModelInfo(hpsIndex).base & ...
                [results.beta]  == hpsSets.scModelInfo(hpsIndex).beta & ...
                [results.gamma] == hpsSets.gamma(hpsIndex));

            if isempty(entryIdx)
                % add new configuration entry if not yet in results
                entryIdx = length(results) + 1 ;
                results(entryIdx).label = labels{labelIndex};
                results(entryIdx).base = hpsSets.scModelInfo(hpsIndex).base;
                results(entryIdx).beta = hpsSets.scModelInfo(hpsIndex).beta;
                results(entryIdx).gamma = hpsSets.gamma(hpsIndex);
                results(entryIdx).STLPerformance = [];
            end

            % *** STL ***
            % skip computation if entry and corresponding
            % performance already exists
            if length(results(entryIdx).STLPerformance) < cvIndex

                modelName = sprintf('STLModel_b%d_beta%g_gamma%g_%s_%d', ...
                    hpsSets.scModelInfo(hpsIndex).base,...
                    hpsSets.scModelInfo(hpsIndex).beta,...
                    hpsSets.gamma(hpsIndex), ...
                    labels{labelIndex}, ...
                    cvIndex);

                savedModel = STL('scModel', hpsSets.scModel(hpsIndex), ...
                            'modelName', modelName, ...
                            'modelPath', savePath, ...
                            'scGamma', hpsSets.gamma(hpsIndex), ...
                            'trainSet', trainSet{cvIndex}, ...
                            'testSet', testSet{cvIndex}, ...
                            'labelCreator', labelCreator, ...
                            'modelTrainer', modelTrainer);
                
                % save performance of computed STLModel into resultsFile
                savedData = load(savedModel);
                results(entryIdx).STLPerformance(cvIndex) = ...
                    savedData.testPerfresults.performance;
                
                save(resultsFile, 'results');        
            end
        end
    end
end

% computations for statistics in resultFile
cvFold = length(trainSet);
%add means
meanSTL =  mean(reshape([results.STLPerformance]', cvFold, []), 1);
meanSTL = num2cell(meanSTL);
[results(:).meanSTL] = meanSTL{:};

%add vars
if cvFold == 1
    varSTL = cell(size([results.STLPerformance]));
    varSTL(:) = {0};
else
    varSTL =  var(reshape([results.STLPerformance]', cvFold, []), 1);
    varSTL = num2cell(varSTL);
end
[results(:).varSTL] = varSTL{:};

save(resultsFile, 'results');


