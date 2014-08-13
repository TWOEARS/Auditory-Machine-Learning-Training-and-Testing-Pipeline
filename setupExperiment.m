function esetup = setupExperiment()

esetup.wp2dataCreation.requests{1} = 'ratemap_magnitude';
esetup.wp2dataCreation.requestP{1} = genParStruct( ...
    'nChannels',16, ...
    'rm_scaling', 'magnitude' ... 
    );
esetup.wp2dataCreation.fs = 44100;
esetup.wp2dataCreation.angle = [0];

esetup.blockCreation.blockSize = 500e-3;
esetup.blockCreation.shiftSize = esetup.blockCreation.blockSize / 2;

esetup.Labeling.minBlockToEventRatio = 0.7;

esetup.featureCreation.function = @msFeatures;
esetup.featureCreation.functionParam.derivations = 1;

esetup.hyperParamSearch.epsilons = [1e-3]; 
esetup.hyperParamSearch.cRange = [-5 5]; 
esetup.hyperParamSearch.gammaRange = [-12 3]; 
esetup.hyperParamSearch.kernels = [0];
esetup.hyperParamSearch.method = 'grid'; % {random, grid, intelliGrid}
esetup.hyperParamSearch.searchBudget = 9;
esetup.hyperParamSearch.dataShare = 1; % [0..1]
esetup.hyperParamSearch.refineStages = 0;
esetup.hyperParamSearch.folds = 4;

esetup.generalizationEstimation.folds = 4;