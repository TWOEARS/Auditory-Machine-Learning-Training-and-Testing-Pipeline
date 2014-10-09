function setup = setupExperiment()

setup.dataCreation.requests{1} = 'ratemap_magnitude';
setup.dataCreation.requestP{1} = genParStruct( ...
   'nChannels',32, ...
   'rm_scaling', 'magnitude' ... 
   );
setup.dataCreation.fs = 44100;
setup.dataCreation.angle = [0];

setup.blockCreation.blockSize = 500e-3;
setup.blockCreation.shiftSize = 167e-3;

setup.Labeling.minBlockToEventRatio = 0.5;

setup.featureCreation.function = @rmFeatures;
setup.featureCreation.functionParam = [];

setup.hyperParamSearch.epsilons = [5e-2]; 
setup.hyperParamSearch.cRange = [-5 3]; 
setup.hyperParamSearch.gammaRange = [-12 3]; 
setup.hyperParamSearch.kernels = [0];
setup.hyperParamSearch.method = 'grid'; % {random, grid, intelliGrid}
setup.hyperParamSearch.searchBudget = 7;
setup.hyperParamSearch.dataShare = 0.25; % [0..1]
setup.hyperParamSearch.refineStages = 0;
setup.hyperParamSearch.folds = 4;

setup.generalizationEstimation.folds = 5;

setup.data.trainSetShare = [4 5]; % [a b] read as: \frac{a}{b}
