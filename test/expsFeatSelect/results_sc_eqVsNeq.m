function results_sc_eqVsNeq

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
boxplot_performance( 'sc,glmnet,fs1 vs fs3,eq vs neq', ...
                     {'fs1, eq', 'fs1, neq', ...
                      'fs3, eq', 'fs3, neq'}, ...
                     [tp_sc{1,:,:,:,1}], [tp_sc{1,:,:,:,2}], ...
                     [tp_sc{2,:,:,:,1}], [tp_sc{2,:,:,:,2}] );

%%
boxplot_performance( 'sc,glmnet+svm fs1,azms+gos,fc1 vs fc2,eq vs neq', ...
                     {'binaural, eq', 'monaural, eq', 'binaural, neq', 'monaural, neq'}, ...
                     [tp_sc{[1,4],1,:,1:2,1}], [tp_sc{[1,4],2,:,1:2,1}], ...
                     [tp_sc{[1,4],1,:,1:2,2}], [tp_sc{[1,4],2,:,1:2,2}]);

%%
boxplot_performance( 'sc,glmnet&svm fs1,gos&dwn,fc2 vs fc3,eq vs neq', ...
                     {'varBlockLengths, eq', 'monaural, eq', 'varBlockLengths, neq', 'monaural, neq'}, ...
                     [tp_sc{[1,4],3,:,2:3,1}], [tp_sc{[1,4],2,:,2:3,1}], ...
                     [tp_sc{[1,4],3,:,2:3,2}], [tp_sc{[1,4],2,:,2:3,2}]);

%%
boxplot_performance( 'sc,glmnet,gos,fc1 vs fc2 vs fc3 vs fc4, eq vs neq', ...
                     {'eq,binaural','neq,binaural','eq,monaural','neq,monaural',...
                      'eq,varBlockLengths','neq,varBlockLengths',...
                      'eq,varFreqRes','neq,varFreqRes'}, ...
                     [tp_sc{1,1,:,2,1}], [tp_sc{1,1,:,2,2}], ...
                     [tp_sc{1,2,:,2,1}], [tp_sc{1,2,:,2,2}], ...
                     [tp_sc{1,3,:,2,1}], [tp_sc{1,3,:,2,2}],...
                     [tp_sc{1,4,:,2,1}], [tp_sc{1,4,:,2,2}] );

% fc1 AND fc3 are better than fc2. -> combination?
% why is fc4 worse than fc2?


%%
boxplot_performance( 'sc,glmnet&svm fs1,classes,eq vs neq', ...
                     {'alarm, eq', 'alarm, neq', ...
                      'baby, eq', 'baby, neq', ...
                      'female, eq', 'female, neq', ...
                      'fire, eq', 'fire, neq'},...
                     [tp_sc{[1,4],:,1,:,1}], [tp_sc{[1,4],:,1,:,2}], ...
                     [tp_sc{[1,4],:,2,:,1}], [tp_sc{[1,4],:,2,:,2}], ...
                     [tp_sc{[1,4],:,3,:,1}], [tp_sc{[1,4],:,3,:,2}], ...
                     [tp_sc{[1,4],:,4,:,1}], [tp_sc{[1,4],:,4,:,2}] );

