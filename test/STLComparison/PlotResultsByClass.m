function PlotResultsByClass(path, labels)

data = load(fullfile(path, 'STLComparison_results.mat'));
res = data.results;

for labelIdx=1:length(labels)
    figure;
    hold on;
    idx = find( cellfun(@(x) strcmp(x,labels{labelIdx}), {res.label}) );
    portions    = [res(idx).portion].*100;
    meanSTL     = [res(idx).meanSTL];
    varSTL     = [res(idx).varSTL];
    meanPure  = [res(idx).meanPure];
    varPure  = [res(idx).varPure];
    
    plot(portions,meanSTL,'b-*', portions, meanPure, 'r--o');   
    
    errorArea( portions, meanSTL - sqrt(varSTL),...
        meanSTL + sqrt(varSTL), 'b');
    
    errorArea( portions, meanPure - sqrt(varPure),...
        meanPure + sqrt(varPure), 'r');

    % description
    xlabel('portion of sound files for training in %');
    ylabel('classification performance');
    title(labels{labelIdx});
    legend('Self-taught learning', 'LASSO', 'Location','southeast');
    hold off;
end

