clear;

data = load('Results b100_0.4_0.4_maxData20000/STLComparison_results.mat');

results = data.results;

cvFold = length(results(1).STLPerformance);
trainingSetPortions = unique([results.portion]);

%add means
meanSTL =  mean(reshape([results.STLPerformance]', cvFold, []), 1);
meanSTL = num2cell(meanSTL);
[results(:).meanSTL] = meanSTL{:};

meanPure = mean(reshape([results.PurePerformance]', cvFold, []), 1);
meanPure = num2cell(meanPure);
[results(:).meanPure] = meanPure{:};

%add vars
varSTL =  var(reshape([results.STLPerformance]', cvFold, []), 1);
varSTL = num2cell(varSTL);
[results(:).varSTL] = varSTL{:};

varPure = var(reshape([results.PurePerformance]', cvFold, []), 1);
varPure = num2cell(varPure);
[results(:).varPure] = varPure{:};

save(resultsFile, 'results');

% compute overall results 
overallMeanSTL  = arrayfun( @(x) mean([results([results.portion] == x).meanSTL]), trainingSetPortions);
overallMeanPure = arrayfun( @(x) mean([results([results.portion] == x).meanPure]), trainingSetPortions);

overall.meanSTL  = overallMeanSTL;
overall.meanPure = overallMeanPure;

overallVarSTL  = arrayfun( @(x) var([results([results.portion] == x).meanSTL]), trainingSetPortions);
overallVarPure = arrayfun( @(x) var([results([results.portion] == x).meanPure]), trainingSetPortions);

overall.varSTL  = overallVarSTL;
overall.varPure = overallVarPure;

splitted = strsplit(resultsFile, '_');
overallFile = strcat(splitted{1:end - 1}, '_overall.mat');
save(overallFile, 'overall');
