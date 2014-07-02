function esetup = setupExperiment()

esetup.wp2dataCreation.fsHz = 44.1E3;
esetup.wp2dataCreation.nErbs = 1;
esetup.wp2dataCreation.nChannels = 32;
esetup.wp2dataCreation.mEarF = true;
esetup.wp2dataCreation.fLowHz = 80;
esetup.wp2dataCreation.fHighHz = 8000;
esetup.wp2dataCreation.ihcMethod = 'halfwave';
esetup.wp2dataCreation.winSizeSec = 20E-3;
esetup.wp2dataCreation.hopSizeSec = 10E-3;
esetup.wp2dataCreation.winType = 'hann';
esetup.wp2dataCreation.bNormRMS = false;
esetup.wp2dataCreation.bAlign = false;      % Time-align auditory channels
esetup.wp2dataCreation.maxDelaySec = 1.0E-3;
esetup.wp2dataCreation.strCues = { 'ratemap_magnitude' };
esetup.wp2dataCreation.strFeatures = { };
esetup.wp2dataCreation.angle = [0];
esetup.wp2dataCreation.head = 'QU_KEMAR_anechoic_3m.mat';

esetup.blockCreation.blockSize = 500e-3;
esetup.blockCreation.shiftSize = esetup.blockCreation.blockSize / 2;

esetup.Labeling.minBlockToEventRatio = 0.8;

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