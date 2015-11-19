function results_ClassificationAlgorithms()

tp_sc = cell(5,4,4,3,2); % alg, fc, class, scGrp, eqOrNeq

%% 'glmnet_azms_test.mat'
load('glmnet_azms_test.mat')
glmnet_azms_test_mat_tp_b = cellSqueezeFun( @(cc)(mean([cc{:}])), test_performances_b, 1 );
glmnet_azms_test_mat_tp_hws = cellSqueezeFun( @(cc)(mean([cc{:}])), test_performances_hws, 1 );

for ii = 1 : 4, for jj = 1 : 4, for ff = 1 : 2, for cc = 1 : 4
    if ii == jj
        tp_sc{1,ff,cc,1,1} = [tp_sc{1,ff,cc,1,1} glmnet_azms_test_mat_tp_b(:,cc,ff,ii,ii)];
        tp_sc{2,ff,cc,1,1} = [tp_sc{2,ff,cc,1,1} glmnet_azms_test_mat_tp_hws(:,cc,ff,ii,ii)];
    else
        tp_sc{1,ff,cc,1,2} = [tp_sc{1,ff,cc,1,2} glmnet_azms_test_mat_tp_b(:,cc,ff,ii,jj)];
        tp_sc{2,ff,cc,1,2} = [tp_sc{2,ff,cc,1,2} glmnet_azms_test_mat_tp_hws(:,cc,ff,ii,jj)];
    end
    tp_sc{1,ff,cc,1,1} = tp_sc{1,ff,cc,1,1}(:)';
    tp_sc{1,ff,cc,1,2} = tp_sc{1,ff,cc,1,2}(:)';
    tp_sc{2,ff,cc,1,1} = tp_sc{2,ff,cc,1,1}(:)';
    tp_sc{2,ff,cc,1,2} = tp_sc{2,ff,cc,1,2}(:)';
end; end; end; end;

%% 'glmnet_azms_' classes{cc} '_svm.mat'
classes = {'alarm', 'baby', 'femaleSpeech', 'fire'};
for cc = 1 : 4
load(['glmnet_azms_' classes{cc} '_svm.mat']);
svm_azms_test_mat_tp_b = cellSqueezeFun( @(cc)(mean([cc{:}])), test_performances, 1 );
for ii = 1 : 4, for jj = 1 : 4, for ff = 1 : 2
for ll = 1 : 3
    if ii == jj
        tp_sc{2+ll,ff,cc,1,1} = [tp_sc{2+ll,ff,cc,1,1} svm_azms_test_mat_tp_b(:,ll,ff,ii,ii)];
    else
        tp_sc{2+ll,ff,cc,1,2} = [tp_sc{2+ll,ff,cc,1,2} svm_azms_test_mat_tp_b(:,ll,ff,ii,jj)];
    end
    tp_sc{2+ll,ff,cc,1,1} = tp_sc{2+ll,ff,cc,1,1}(:)';
    tp_sc{2+ll,ff,cc,1,2} = tp_sc{2+ll,ff,cc,1,2}(:)';
end
end; end; end;
end

%% 'glmnet_gos_' classes{cc} '_test.mat'
classes = {'alarm', 'baby', 'femaleSpeech', 'fire'};
for cc = 1 : 4
load(['glmnet_gos_' classes{cc} '_test.mat']);
for ii = 1 : 3, for jj = 1 : 3, for ff = 1 : 4
for kk = 1 : 4, for mm = 1 : 4
    if ii == jj  && kk == mm
        tp_sc{1,ff,cc,2,1} = [tp_sc{1,ff,cc,2,1} test_performances_b{kk,ff,ii,ii,kk}];
        tp_sc{2,ff,cc,2,1} = [tp_sc{2,ff,cc,2,1} test_performances_hws{kk,ff,ii,ii,kk}];
    else
        tp_sc{1,ff,cc,2,2} = [tp_sc{1,ff,cc,2,2} test_performances_b{kk,ff,ii,jj,mm}];
        tp_sc{2,ff,cc,2,2} = [tp_sc{2,ff,cc,2,2} test_performances_hws{kk,ff,ii,jj,mm}];
    end
end; end;
end; end; end;
end

%% 'glmnet_gos_' classes{cc} '_svm.mat'
classes = {'alarm', 'baby', 'femaleSpeech', 'fire'};
for cc = 1 : 4
load(['glmnet_gos_' classes{cc} '_svm.mat']);
for ii = 1 : 3, for jj = 1 : 3, for ff = 1 : 4
for kk = 1 : 4, for mm = 1 : 4
for ll = 1 : 3
    if size(test_performances,1) < kk  ||  size(test_performances,2) < ll || ...
            size(test_performances,3) < ff  ||  size(test_performances,4) < ii  ||  ...
            size(test_performances,5) < jj  || size(test_performances,6) < mm
        continue;
    end
    if ii == jj  && kk == mm
        tp_sc{2+ll,ff,cc,2,1} = [tp_sc{2+ll,ff,cc,2,1} test_performances{kk,ll,ff,ii,ii,kk}];
    else
        tp_sc{2+ll,ff,cc,2,2} = [tp_sc{2+ll,ff,cc,2,2} test_performances{kk,ll,ff,ii,jj,mm}];
    end
end
end; end;
end; end; end;
end

%% 'RESULTS_crosstest_lasso.mat'
load('RESULTS_crosstest_lasso.mat');
for cc = 1 : 4
    clssIdx = find( strcmpi( classname{cc}, classes ) );
    for ii = 1 : numel( snr_set ), for jj = 1 : numel( snr_set )
        if ii == jj
            tp_sc{1,2,clssIdx,3,1} = [tp_sc{1,2,clssIdx,3,1} P{cc}(ii,jj)];
        else
            tp_sc{1,2,clssIdx,3,2} = [tp_sc{1,2,clssIdx,3,2} P{cc}(ii,jj)];
        end
    end, end
end

%% 'RESULTS_crosstest_vb_lasso.mat'
load('RESULTS_crosstest_vb_lasso.mat');
for cc = 1 : 4
    clssIdx = find( strcmpi( classname{cc}, classes ) );
    for ii = 1 : numel( snr_set ), for jj = 1 : numel( snr_set )
        if ii == jj
            tp_sc{1,3,clssIdx,3,1} = [tp_sc{1,3,clssIdx,3,1} P{cc}(ii,jj)];
        else
            tp_sc{1,3,clssIdx,3,2} = [tp_sc{1,3,clssIdx,3,2} P{cc}(ii,jj)];
        end
    end, end
end

%% 'RESULTS_crosstest_svm.mat'
load('RESULTS_crosstest_svm.mat');
for cc = 1 : 4
    clssIdx = find( strcmpi( classname{cc}, classes ) );
    for ii = 1 : numel( snr_set ), for jj = 1 : numel( snr_set )
        if ii == jj
            tp_sc{3,2,clssIdx,3,1} = [tp_sc{3,2,clssIdx,3,1} P{cc}(ii,jj)];
        else
            tp_sc{3,2,clssIdx,3,2} = [tp_sc{3,2,clssIdx,3,2} P{cc}(ii,jj)];
        end
    end, end
end

%% 'RESULTS_crosstest_fs+svm.mat'
load('RESULTS_crosstest_fs+svm.mat');
for cc = 1 : 4
    clssIdx = find( strcmpi( classname{cc}, classes ) );
    for ii = 1 : numel( snr_set ), for jj = 1 : numel( snr_set )
        if ii == jj
            tp_sc{4,2,clssIdx,3,1} = [tp_sc{4,2,clssIdx,3,1} P{cc}(ii,jj)];
        else
            tp_sc{4,2,clssIdx,3,2} = [tp_sc{4,2,clssIdx,3,2} P{cc}(ii,jj)];
        end
    end, end
end


%%
%%
% boxplot_performance( 'sc,azms,eq,fc1+fc2,algs', ...
%                      {'fs1-glmnet', 'fs3-glmnet', 'O-svm', 'fs1-svm', 'fs3-svm'}, ...
%                      [tp_sc{1,1:2,:,1,1}], [tp_sc{2,1:2,:,1,1}], ...
%                      [tp_sc{3,1:2,:,1,1}], [tp_sc{4,1:2,:,1,1}], [tp_sc{5,1:2,:,1,1}] );

%%
% boxplot_performance( 'sc,gos,eq,fc1+fc2,algs', ...
%                      {'fs1-lasso', 'fs3-lasso', 'O-svm', 'fs1-svm', 'fs3-svm'}, ...
%                      [tp_sc{1,1:2,:,2,1}], [tp_sc{2,1:2,:,2,1}], ...
%                      [tp_sc{3,1:2,:,2,1}], [tp_sc{4,1:2,:,2,1}], [tp_sc{5,1:2,:,2,1}] );

%%
% boxplot_performance( 'sc,dwn,eq,fc2,algs', ...
%                      {'fs1-lasso', 'O-svm', 'fs1-svm'}, ...
%                      [tp_sc{1,2,:,3,1}], ...
%                      [tp_sc{3,2,:,3,1}], [tp_sc{4,2,:,3,1}] );

%%
boxplot_performance( 'sc,azms&gos,iso,fc1 vs fc2,algs', ...
                     {'monaural fs1-lasso', 'binaural fs1-lasso', ...
                      'monaural fs3-lasso', 'binaural fs3-lasso', ...
                      'monaural O-svm', 'binaural O-svm', 'monaural fs1-svm', ...
                      'binaural fs1-svm', 'monaural fs3-svm', 'binaural fs3-svm'}, ...
                     [tp_sc{1,2,:,1:2,1}], [tp_sc{1,1,:,1:2,1}], ...
                     [tp_sc{2,2,:,1:2,1}], [tp_sc{2,1,:,1:2,1}], ...
                     [tp_sc{3,2,:,1:2,1}], [tp_sc{3,1,:,1:2,1}], [tp_sc{4,2,:,1:2,1}], ...
                     [tp_sc{4,1,:,1:2,1}], [tp_sc{5,2,:,1:2,1}], [tp_sc{5,1,:,1:2,1}] );

%%
boxplot_performance( 'sc,azms&gos,eq,fc1&fc2,algs', ...
                     {'fs1-lasso', 'fs3-lasso', 'O-svm', 'fs1-svm', 'fs3-svm'}, ...
                     [tp_sc{1,1:2,:,1:2,1}], [tp_sc{2,1:2,:,1:2,1}], ...
                     [tp_sc{3,1:2,:,1:2,1}], [tp_sc{4,1:2,:,1:2,1}], [tp_sc{5,1:2,:,1:2,1}] );

%%
boxplot_performance( 'sc,alarm,azms&gos,eq,fc1&fc2,algs', ...
                     {'fs1-lasso', 'fs3-lasso', 'O-svm', 'fs1-svm', 'fs3-svm'}, ...
                     [tp_sc{1,1:2,1,1:2,1}], [tp_sc{2,1:2,1,1:2,1}], ...
                     [tp_sc{3,1:2,1,1:2,1}], [tp_sc{4,1:2,1,1:2,1}], [tp_sc{5,1:2,1,1:2,1}] );

%%
boxplot_performance( 'sc,baby,azms&gos,eq,fc1&fc2,algs', ...
                     {'fs1-lasso', 'fs3-lasso', 'O-svm', 'fs1-svm', 'fs3-svm'}, ...
                     [tp_sc{1,1:2,2,1:2,1}], [tp_sc{2,1:2,2,1:2,1}], ...
                     [tp_sc{3,1:2,2,1:2,1}], [tp_sc{4,1:2,2,1:2,1}], [tp_sc{5,1:2,2,1:2,1}] );

%%
boxplot_performance( 'sc,female,azms&gos,eq,fc1&fc2,algs', ...
                     {'fs1-lasso', 'fs3-lasso', 'O-svm', 'fs1-svm', 'fs3-svm'}, ...
                     [tp_sc{1,1:2,3,1:2,1}], [tp_sc{2,1:2,3,1:2,1}], ...
                     [tp_sc{3,1:2,3,1:2,1}], [tp_sc{4,1:2,3,1:2,1}], [tp_sc{5,1:2,3,1:2,1}] );

%%
boxplot_performance( 'sc,fire,azms&gos,eq,fc1&fc2,algs', ...
                     {'fs1-lasso', 'fs3-lasso', 'O-svm', 'fs1-svm', 'fs3-svm'}, ...
                     [tp_sc{1,1:2,4,1:2,1}], [tp_sc{2,1:2,4,1:2,1}], ...
                     [tp_sc{3,1:2,4,1:2,1}], [tp_sc{4,1:2,4,1:2,1}], [tp_sc{5,1:2,4,1:2,1}] );

%%
% boxplot_performance( 'sc,azms&gos&dwn,eq,fc2,algs', ...
%                      {'fs1-lasso', 'O-svm', 'fs1-svm'}, ...
%                      [tp_sc{1,2,:,:,1}], ...
%                      [tp_sc{3,2,:,:,1}], [tp_sc{4,2,:,:,1}] );

%%
% boxplot_performance( 'sc,azms,fc1+fc2,neq,algs', ...
%                      {'fs1-lasso', 'fs3-lasso','fs1-svm'}, ...
%                      [tp_sc{1,1:2,:,1,2}], ...
%                      [tp_sc{2,1:2,:,1,2}], [tp_sc{4,1:2,:,1,2}] );

%%
% boxplot_performance( 'sc,gos,fc1+fc2,neq,algs', ...
%                      {'fs1-lasso', 'fs3-lasso', 'fs1-svm'}, ...
%                      [tp_sc{1,1:2,:,2,2}], ...
%                      [tp_sc{2,1:2,:,2,2}], [tp_sc{4,1:2,:,2,2}] );

%%
% boxplot_performance( 'sc,dwn,fc2,neq,algs', ...
%                      {'fs1-lasso', 'O-svm', 'fs1-svm'}, ...
%                      [tp_sc{1,2,:,3,2}], ...
%                      [tp_sc{3,2,:,3,2}], [tp_sc{4,2,:,3,2}] );


%%
boxplot_performance( 'sc,azms&gos,neq,fc1&fc2,algs', ...
                     {'fs1-lasso', 'fs3-lasso', 'fs1-svm'}, ...
                     [tp_sc{1,1:2,:,1:2,2}], [tp_sc{2,1:2,:,1:2,2}], ...
                     [tp_sc{4,1:2,:,1:2,2}] );

%%
% boxplot_performance( 'sc,azms&gos&dwn,neq,fc2,algs', ...
%                      {'fs1-lasso', 'fs1-svm'}, ...
%                      [tp_sc{1,2,:,:,2}], [tp_sc{4,2,:,:,2}] );

%%
%%
% boxplot_performance( 'sc,lasso+svm fs1,azms+gos,fc1 vs fc2,eq vs neq', ...
%                      {'binaural, eq', 'monaural, eq', 'binaural, neq', 'monaural, neq'}, ...
%                      [tp_sc{[1,4],1,:,1:2,1}], [tp_sc{[1,4],2,:,1:2,1}], ...
%                      [tp_sc{[1,4],1,:,1:2,2}], [tp_sc{[1,4],2,:,1:2,2}]);

%%
boxplot_performance( 'sc,glmnet,go+dwn,fc2 vs fc3,eq vs neq', ...
                     {'varBlockLengths, iso', 'monaural, iso', 'varBlockLengths, cross', 'monaural, cross'}, ...
                     [tp_sc{1,3,:,2:3,1}], [tp_sc{1,2,:,2:3,1}], ...
                     [tp_sc{1,3,:,2:3,2}], [tp_sc{1,2,:,2:3,2}]);

%%
boxplot_performance( 'sc,glmnet,gos,fc1 vs fc2 vs fc3 vs fc4, eq vs neq', ...
                     {'iso,binaural','iso,monaural',...
                      'iso,varBlockLengths','iso,varFreqRes',...
                      'cross,binaural','cross,monaural',...
                      'cross,varBlockLengths','cross,varFreqRes'}, ...
                     [tp_sc{1,1,:,2,1}], [tp_sc{1,2,:,2,1}], ...
                     [tp_sc{1,3,:,2,1}], [tp_sc{1,4,:,2,1}], ...
                     [tp_sc{1,1,:,2,2}], [tp_sc{1,2,:,2,2}],...
                     [tp_sc{1,3,:,2,2}], [tp_sc{1,4,:,2,2}] );

% fc1 AND fc3 are better than fc2. -> combination?
% why is fc4 worse than fc2?

% check glmnet go cross tests, also azms

%%
% boxplot_performance( 'sc,glmnet&svm fs1,classes,eq vs neq', ...
%                      {'alarm, eq', 'alarm, neq', ...
%                       'baby, eq', 'baby, neq', ...
%                       'female, eq', 'female, neq', ...
%                       'fire, eq', 'fire, neq'},...
%                      [tp_sc{[1,4],:,1,:,1}], [tp_sc{[1,4],:,1,:,2}], ...
%                      [tp_sc{[1,4],:,2,:,1}], [tp_sc{[1,4],:,2,:,2}], ...
%                      [tp_sc{[1,4],:,3,:,1}], [tp_sc{[1,4],:,3,:,2}], ...
%                      [tp_sc{[1,4],:,4,:,1}], [tp_sc{[1,4],:,4,:,2}] );

