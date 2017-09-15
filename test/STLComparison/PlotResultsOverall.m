function PlotResultsOverall(path, labels, portions)

data = load(fullfile(path, 'STLComparison_overall.mat'));
overall = data.overall;

figure;
hold on;

meanSTL  = overall.meanSTL;
varSTL   = overall.varSTL;
meanPure = overall.meanPure;
varPure  = overall.varPure;
    
plot(portions,meanSTL,'b-*', portions, meanPure, 'r--o'); 

errorArea( portions, meanSTL - sqrt(varSTL),...
        meanSTL + sqrt(varSTL), 'b');
    
errorArea( portions, meanPure - sqrt(varPure),...
        meanPure + sqrt(varPure), 'r');

% description
xlabel('portion of sound files for training in %');
ylabel('classification performance');
title('general comparison');
legend('Self-taught learning', 'LASSO', 'Location','southeast');

end
