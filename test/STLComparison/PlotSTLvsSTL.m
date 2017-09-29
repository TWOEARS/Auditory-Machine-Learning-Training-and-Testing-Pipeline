
clear;

labels = {'alarm', 'baby', 'femaleSpeech', 'fire'};
portions = 10:10:100;

path1 = 'diverse/b100_0.4_0.4_20000 20000samples'; 
path2 = 'diverse/b100_0.4_0.4_100000_inclNigens 20000samples';

data_1 = load(fullfile(path1, 'STLComparison_overall.mat'));
overall_1 = data_1.overall;

data_2 = load(fullfile(path2, 'STLComparison_overall.mat'));
overall_2 = data_2.overall;

figure;
hold on;

meanSTL_1  = overall_1.meanSTL;
meanPure_1 = overall_1.meanPure;

meanSTL_2  = overall_2.meanSTL;
meanPure_2 = overall_2.meanPure;
    
plot(portions,meanSTL_1,'b-*');
plot(portions,meanSTL_2,'g-x');
plot(portions, meanPure_1, 'r--o');

% description
xlabel('portion of sound files for training in %');
ylabel('classification performance');
title('comparison overall performances');
legend('STL, random unlabeled data ', ...
    'STL, unlabeled data incl. NIGENS training data', ...
    'Pure LASSO', 'Location','southeast');