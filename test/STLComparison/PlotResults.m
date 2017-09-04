clear;

path = 'profile/';
%Results b100_0.4_0.4_maxData20000/
data = load([path 'STLComparison_results.mat']);
labels = {'alarm', 'baby', 'femaleSpeech', 'fire'};
res = data.results;

for labelIdx=1:length(labels)
    figure;
    idx = find( cellfun(@(x) strcmp(x,labels{labelIdx}), {res.label}) );
    portions    = [res(idx).portion].*100;
    meanSTL     = [res(idx).meanSTL];
    meanGlmNet  = [res(idx).meanGlmNet];
    
    plot(portions,meanSTL,'-*', portions, meanGlmNet, '--o');   

    % description
    xlabel('portion of sound files for training in %');
    ylabel('classification performance');
    title(labels{labelIdx});
    legend('Self-taught learning', 'LASSO', 'Location','southeast');
end

data = load([path 'STLComparison_overall.mat']);
overall = data.overall;

figure;
portions    = 0.3:0.1:1;
meanSTL     = overall.meanSTL;
meanGlmNet  = overall.meanGlmNet;
    
plot(portions,meanSTL,'-*', portions, meanGlmNet, '--o');   
% description
xlabel('portion of sound files for training in %');
ylabel('classification performance');
title('general comparison');
legend('Self-taught learning', 'LASSO', 'Location','southeast');


