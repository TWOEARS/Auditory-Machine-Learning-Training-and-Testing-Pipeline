clear;

path = '';
%Results b100_0.4_0.4_maxData20000/
data = load([path 'STLComparison_results.mat']);
labels = {'alarm', 'baby', 'femaleSpeech', 'fire'};
res = data.results;

for labelIdx=1:length(labels)
    figure;
    idx = find( cellfun(@(x) strcmp(x,labels{labelIdx}), {res.label}) );
    portions    = [res(idx).portion].*100;
    meanSTL     = [res(idx).meanSTL];
    meanPure  = [res(idx).meanPure];
    
    plot(portions,meanSTL,'-*', portions, meanPure, '--o');   

    % description
    xlabel('portion of sound files for training in %');
    ylabel('classification performance');
    title(labels{labelIdx});
    legend('Self-taught learning', 'LASSO', 'Location','southeast');
end

data = load([path 'STLComparison_overall.mat']);
overall = data.overall;

figure;
meanSTL     = overall.meanSTL;
meanPure  = overall.meanPure;
    
plot(portions,meanSTL,'-*', portions, meanPure, '--o');   
% description
xlabel('portion of sound files for training in %');
ylabel('classification performance');
title('general comparison');
legend('Self-taught learning', 'LASSO', 'Location','southeast');


