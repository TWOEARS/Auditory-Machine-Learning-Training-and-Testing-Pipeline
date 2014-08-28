function esetup = setupExperiment()

esetup.wp2dataCreation.requests{1} = 'ratemap_magnitude';
esetup.wp2dataCreation.requestP{1} = genParStruct( ...
    'nChannels',32, ...
    'rm_scaling', 'magnitude' ... 
    );
esetup.wp2dataCreation.fs = 44100;
esetup.wp2dataCreation.angle = [0];

esetup.blockCreation.blockSize = 500e-3;
esetup.blockCreation.shiftSize = esetup.blockCreation.blockSize / 2;

esetup.Labeling.minBlockToEventRatio = 0.75;

esetup.featureCreation.function = @rmFeatures;
esetup.featureCreation.functionParam = [];

esetup.hyperParamSearch.epsilons = [5e-2]; 
esetup.hyperParamSearch.cRange = [-5 3]; 
esetup.hyperParamSearch.gammaRange = [-12 3]; 
esetup.hyperParamSearch.kernels = [0];
esetup.hyperParamSearch.method = 'grid'; % {random, grid, intelliGrid}
esetup.hyperParamSearch.searchBudget = 9;
esetup.hyperParamSearch.dataShare = 0.25; % [0..1]
esetup.hyperParamSearch.refineStages = 0;
esetup.hyperParamSearch.folds = 3;

esetup.generalizationEstimation.folds = 5;

esetup.data.trainSetShare = 0.8; % [0..1]