function results_mc_fs

tp_mc = cell(3,4); % fc, class
l_mc = cell(3,4); % fc, class
l1_mc = cell(3,4); % fc, class
l3_mc = cell(3,4); % fc, class
n_mc = cell(3,4); % fc, class
tp_svm_mc = cell(3,4,3); % fc, class, o-1-3
n_svmo_mc = zeros(3,4); % fc, class

%% 'glmnet_mc1_test.mat'
load('glmnet_mc1_test.mat')

tp_mc = test_performances;
l_mc = lambdas;
l1_mc = lambda_b;
l3_mc = lambda_hws;
n_mc = nCoefs;
n_svmo_mc = cellfun( @numel, impacts_b );


%% 'glmnet_mc1_' classes{cc} '_svm.mat'
classes = {'alarm', 'baby', 'femaleSpeech', 'fire'};
for cc = 1 : 4
load(['glmnet_mc1_' classes{cc} '_svm.mat']);
for ll = 1 : 3
for fc = 1 : numel( test_performances(:,ll) )
    tp_svm_mc(fc,cc,ll) = test_performances(fc,ll);
end
end
end


%% all classes, all fcs

for cc = 1 : 4
for fc = 1 : 3
    plotLambdaNCoefsPerf( l_mc{fc,cc}, n_mc{fc,cc}, tp_mc{fc,cc}, [], ...
                          [' - class ' num2str(cc) ' - fc' num2str( fc )],...
                          l1_mc{fc,cc},l3_mc{fc,cc},...
                          tp_svm_mc{fc,cc,2},tp_svm_mc{fc,cc,3},tp_svm_mc{fc,cc,1},...
                          n_svmo_mc(fc,cc) );
end
end

%% #features/grp over perf

