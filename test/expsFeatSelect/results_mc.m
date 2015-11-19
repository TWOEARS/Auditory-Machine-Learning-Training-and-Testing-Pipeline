function results_mc

tp_mc = cell(5,3,4); % alg, fc, class
tp_mc_testOnSc = cell(5,3,4,18); % alg, fc, class, testSc
tp_sc = cell(5,4,4,3,2); % alg, fc, class, scGrp, eqOrNeq
tp_sc_db = cell(5,4,4,3,2,7); % alg, fc, class, scGrp, eqOrNeq, tEdBgrp

%% 'glmnet_mc1_test.mat'
load('glmnet_mc1_test.mat')

tp_mc(1,:,:) = test_performances_b;
tp_mc(2,:,:) = test_performances_hws;

%% 'glmnet_mc1_' classes{cc} '_svm.mat'
classes = {'alarm', 'baby', 'femaleSpeech', 'fire'};
for cc = 1 : 4
load(['glmnet_mc1_' classes{cc} '_svm.mat']);
for ll = 1 : 3
for fc = 1 : numel( test_performances(:,ll) )
    tp_mc(2+ll,fc,cc) = test_performances(fc,ll);
end
end
end

%% 'glmnet_mc1_test_sc.mat'
load('glmnet_mc1_test_sc.mat')

tp_mc_testOnSc(1,:,:,:) = test_performances_b;
tp_mc_testOnSc(2,:,:,:) = test_performances_hws;

%% 'glmnet_svm_mc1_test_sc.mat'
load('glmnet_svm_mc1_test_sc.mat')
tp_mc_testOnSc(4,1,:,:) = permute( test_performances(:,:,:,2), [4 1 2 3] );

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
            if ii == 1
                tp_sc_db{1,2,clssIdx,3,1,1} = [tp_sc_db{1,2,clssIdx,3,1,1} P{cc}(ii,jj)];
            elseif ii == 5
                tp_sc_db{1,2,clssIdx,3,1,2} = [tp_sc_db{1,2,clssIdx,3,1,2} P{cc}(ii,jj)];
            elseif ii == 6
                tp_sc_db{1,2,clssIdx,3,1,3} = [tp_sc_db{1,2,clssIdx,3,1,3} P{cc}(ii,jj)];
            end
        else
            tp_sc{1,2,clssIdx,3,2} = [tp_sc{1,2,clssIdx,3,2} P{cc}(ii,jj)];
            if jj == 2
                tp_sc_db{1,2,clssIdx,3,2,1} = [tp_sc_db{1,2,clssIdx,3,2,1} P{cc}(ii,jj)];
            elseif jj == 4
                tp_sc_db{1,2,clssIdx,3,2,2} = [tp_sc_db{1,2,clssIdx,3,2,2} P{cc}(ii,jj)];
            elseif jj == 7
                tp_sc_db{1,2,clssIdx,3,2,3} = [tp_sc_db{1,2,clssIdx,3,2,3} P{cc}(ii,jj)];
            end
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
            if ii == 1
                tp_sc_db{1,3,clssIdx,3,1,1} = [tp_sc_db{1,3,clssIdx,3,1,1} P{cc}(ii,jj)];
            elseif ii == 5
                tp_sc_db{1,3,clssIdx,3,1,2} = [tp_sc_db{1,3,clssIdx,3,1,2} P{cc}(ii,jj)];
            elseif ii == 6
                tp_sc_db{1,3,clssIdx,3,1,3} = [tp_sc_db{1,3,clssIdx,3,1,3} P{cc}(ii,jj)];
            end
        else
            tp_sc{1,3,clssIdx,3,2} = [tp_sc{1,3,clssIdx,3,2} P{cc}(ii,jj)];
            if jj == 2
                tp_sc_db{1,3,clssIdx,3,2,1} = [tp_sc_db{1,3,clssIdx,3,2,1} P{cc}(ii,jj)];
            elseif jj == 4
                tp_sc_db{1,3,clssIdx,3,2,2} = [tp_sc_db{1,3,clssIdx,3,2,2} P{cc}(ii,jj)];
            elseif jj == 7
                tp_sc_db{1,3,clssIdx,3,2,3} = [tp_sc_db{1,3,clssIdx,3,2,3} P{cc}(ii,jj)];
            end
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
            if ii == 1
                tp_sc_db{4,2,clssIdx,3,1,1} = [tp_sc_db{4,2,clssIdx,3,1,1} P{cc}(ii,jj)];
            elseif ii == 5
                tp_sc_db{4,2,clssIdx,3,1,2} = [tp_sc_db{4,2,clssIdx,3,1,2} P{cc}(ii,jj)];
            elseif ii == 6
                tp_sc_db{4,2,clssIdx,3,1,3} = [tp_sc_db{4,2,clssIdx,3,1,3} P{cc}(ii,jj)];
            end
        else
            tp_sc{4,2,clssIdx,3,2} = [tp_sc{4,2,clssIdx,3,2} P{cc}(ii,jj)];
            if jj == 2
                tp_sc_db{4,2,clssIdx,3,2,1} = [tp_sc_db{4,2,clssIdx,3,2,1} P{cc}(ii,jj)];
            elseif jj == 4
                tp_sc_db{4,2,clssIdx,3,2,2} = [tp_sc_db{4,2,clssIdx,3,2,2} P{cc}(ii,jj)];
            elseif jj == 7
                tp_sc_db{4,2,clssIdx,3,2,3} = [tp_sc_db{4,2,clssIdx,3,2,3} P{cc}(ii,jj)];
            end
        end
    end, end
end


%% all fcs, all algs, all classes

figure( 'Name', 'mc per class. lasso; mc train set; mc test set', 'position', [0, 0, 900, 600] )
hold all;
plot( [1, 2, 3, 4], [tp_mc{1,1,:}], 'or', 'DisplayName','fs1-lasso, monaural', 'LineWidth', 3 );
plot( [1, 2, 3, 4], [tp_mc{2,1,:}], 'oc', 'DisplayName','fs3-lasso, monaural', 'LineWidth', 2 );
plot( [1, 2, 3, 4], [tp_mc{3,1,:}], 'og', 'DisplayName','O-svm, monaural', 'LineWidth', 3 );
plot( [1, 2, 3, 4], [tp_mc{4,1,:}], 'ob', 'DisplayName','fs1-svm, monaural', 'LineWidth', 3 );
plot( [1, 2, 3, 4], [tp_mc{5,1,:}], 'om', 'DisplayName','fs3-svm, monaural', 'LineWidth', 2 );
plot( [0.90, 1.90, 2.90, 3.90], [tp_mc{1,2,:}], 'sr', 'DisplayName','fs1-lasso, varBlockLengths', 'LineWidth', 3 );
plot( [0.90, 1.90, 2.90, 3.90], [tp_mc{2,2,:}], 'sc', 'DisplayName','fs3-lasso, varBlockLengths', 'LineWidth', 2 );
plot( [0.90, 1.90, 2.90, 3.90], [tp_mc{3,2,:}], 'sg', 'DisplayName','O-svm, varBlockLengths', 'LineWidth', 3 );
plot( [0.90, 1.90, 2.90, 3.90], [tp_mc{4,2,:}], 'sb', 'DisplayName','fs1-svm, varBlockLengths', 'LineWidth', 3 );
plot( [0.90, 1.90, 2.90, 3.90], [tp_mc{5,2,:}], 'sm', 'DisplayName','fs3-svm, varBlockLengths', 'LineWidth', 2 );
plot( [1.10, 2.10, 3.10, 4.10], [tp_mc{1,3,:}], 'dr', 'DisplayName','fs1-lasso, varFreqRes', 'LineWidth', 3 );
plot( [1.10, 2.10, 3.10, 4.10], [tp_mc{2,3,:}], 'dc', 'DisplayName','fs3-lasso, varFreqRes', 'LineWidth', 2 );
plot( [1.10, 2.10, 3.10, 4.10], [tp_mc{3,3,:}], 'dg', 'DisplayName','O-svm, varFreqRes', 'LineWidth', 3 );
plot( [1.10, 2.10, 3.10, 4.10], [tp_mc{4,3,:}], 'db', 'DisplayName','fs1-svm, varFreqRes', 'LineWidth', 3 );
plot( [1.10, 2.10, 3.10, 4.10], [tp_mc{5,3,:}], 'dm', 'DisplayName','fs3-svm, varFreqRes', 'LineWidth', 2 );
ylabel( 'performance' );
set( gca, 'XTickLabel',{'alarm','baby','femaleSpeech','fire'}, 'XTick',[1 2 3 4] );
legend( 'show','Location','Best' );
set( gca, 'YLim', [0.8 1] );

savePng( 'mc train mc test,classes,algs' );

%% algs&fcs comparison

figure( 'Name', 'all classes mean. mc train set; mc test set' )
hold all;
bar( cellSqueezeFun( @(cc)(mean([cc{:}])), tp_mc(:,:,:), 3 )' );
ylabel( 'test performance' );
set( gca, ...
     'XTickLabel',...
        {'monaural',...
         'varBlockLengths',...
         'varFreqRes' }, 'XTick',[1 2 3],...
         'YLim', [0.8 1] );
legend( {'fs1-lasso', 'fs3-lasso', 'O-svm', 'fs1-svm', 'fs3-svm'},'Location','Best' );

savePng( 'mc train mc test,classes mean,algs' );

%% glmnet all fcs, by class, test on scs.

boxplot_performance( ...
    'mc&sc train sc test,classes,all fcs,eq,glmnet-fs1',...
    {'mc alarm','sc alarm', 'mc baby', 'sc baby','mc female','sc female', 'mc fire', 'sc fire'},...
     [tp_mc_testOnSc{1,:,1,1:9}],[tp_sc{1,2:4,1,:,1}], ...
     [tp_mc_testOnSc{1,:,2,1:9}],[tp_sc{1,2:4,2,:,1}], ...
     [tp_mc_testOnSc{1,:,3,1:9}],[tp_sc{1,2:4,3,:,1}], ...
     [tp_mc_testOnSc{1,:,4,1:9}],[tp_sc{1,2:4,4,:,1}]);


%% glmnet+svm all fcs, by class, test on scs.

boxplot_performance( ...
    'mc&sc train sc test,classes,all fcs,eq,glmnet&svm-fs1',...
    {'mc alarm','sc alarm', 'mc baby', 'sc baby','mc female','sc female', 'mc fire', 'sc fire'},...
     [tp_mc_testOnSc{[1,4],:,1,1:9}],[tp_sc{[1,4],2:4,1,:,1}], ...
     [tp_mc_testOnSc{[1,4],:,2,1:9}],[tp_sc{[1,4],2:4,2,:,1}], ...
     [tp_mc_testOnSc{[1,4],:,3,1:9}],[tp_sc{[1,4],2:4,3,:,1}], ...
     [tp_mc_testOnSc{[1,4],:,4,1:9}],[tp_sc{[1,4],2:4,4,:,1}]);


%% glmnet&svm fs1, test on scs.

boxplot_performance( ...
    'mc&sc train sc test,all classes,all fcs,glmnet&svm -fs1',...
    {'mc iso','mc cross', 'sc iso', 'sc cross'},...
     [tp_mc_testOnSc{[1,4],:,:,1:9}],[tp_mc_testOnSc{[1,4],:,:,10:18}],...
     [tp_sc{[1,4],2:4,:,:,1}], [tp_sc{[1,4],2:4,:,:,2}] );


%% svm fs1, glmnet fs1, look at particular/grouped sc tests

boxplot_performance( ...
    'mc&sc train sc test;azms;all classes,all fcs,glmnet&svm -fs1',...
    {'mc azms iso','sc azms iso','mc azms cross', 'sc azms cross'},...
     [tp_mc_testOnSc{[1,4],:,:,5:6}],...
     [tp_sc{[1,4],2:4,:,1,1}], [tp_mc_testOnSc{[1,4],:,:,14:15}], [tp_sc{[1,4],2:4,:,1,2}] );

boxplot_performance( ...
    'mc&sc train sc test;gos;all classes,all fcs,glmnet&svm -fs1',...
    {'mc gos iso','sc gos iso','mc gos cross', 'sc gos cross'},...
     [tp_mc_testOnSc{[1,4],:,:,1:4}],...
     [tp_sc{[1,4],2:4,:,2,1}],[tp_mc_testOnSc{[1,4],:,:,10:13}],[tp_sc{[1,4],2:4,:,2,2}] );

boxplot_performance( ...
    'mc&sc train sc test;dwn;all classes,all fcs.glmnet&svm -fs1',...
    {'mc dwn iso', 'sc dwn iso','mc dwn cross', 'sc dwn cross'},...
     [tp_mc_testOnSc{[1,4],:,:,7:9}],...
     [tp_sc{[1,4],2:4,:,3,1}],[tp_mc_testOnSc{[1,4],:,:,16:18}], [tp_sc{[1,4],2:4,:,3,2}] );


%% svm fs1, glmnet fs1, look at snrs (do sc help for difficult distrator situations?)

boxplot_performance( ...
    'mc&sc train sc test;all classes,all fcs.glmnet&svm -fs1;eq,var dB',...
    {'mc dwn iso Inf dB','sc dwn iso Inf dB', ...
     'mc dwn iso 0dB','sc dwn iso 0dB', ...
     'mc dwn iso -10dB', 'sc dwn iso -10dB', },...
     [tp_mc_testOnSc{[1,4],:,:,5}], [tp_sc_db{[1,4],2:4,:,3,1,1}],...
     [tp_mc_testOnSc{[1,4],:,:,8}],[tp_sc_db{[1,4],2:4,:,3,1,2}],...
     [tp_mc_testOnSc{[1,4],:,:,7}], [tp_sc_db{[1,4],2:4,:,3,1,3}]);

boxplot_performance( ...
    'mc&sc train sc test;all classes,all fcs.glmnet&svm -fs1;neq,var test dB',...
    {'mc dwn cross 20dB','sc dwn cross 20dB', ...
     'mc dwn cross 5dB','sc dwn cross 5dB', ...
     'mc dwn cross -20dB', 'sc dwn cross -20dB', },...
     [tp_mc_testOnSc{[1,4],:,:,16}], [tp_sc_db{[1,4],2:4,:,3,2,1}],...
     [tp_mc_testOnSc{[1,4],:,:,18}],[tp_sc_db{[1,4],2:4,:,3,2,2}],...
     [tp_mc_testOnSc{[1,4],:,:,17}], [tp_sc_db{[1,4],2:4,:,3,2,3}]);

%% matrix for johannes

mcOnSc_iso_dims = { {'glmnet-fs1','svm-fs1'},{'alarm','baby','female','fire'},{inf,0,-10} };
mcOnSc_iso(1,:,:) = cell2mat( squeeze( tp_mc_testOnSc(1,1,:,[5,8,7]) ) );
mcOnSc_iso(2,:,:) = cell2mat( squeeze( tp_mc_testOnSc(2,1,:,[5,8,7]) ) );
mcOnSc_cross_dims = { {'glmnet-fs1','svm-fs1'},{'alarm','baby','female','fire'},{20,5,-20} };
mcOnSc_cross(1,:,:) = cell2mat( squeeze( tp_mc_testOnSc(1,1,:,[16,18,17]) ) );
mcOnSc_cross(2,:,:) = cell2mat( squeeze( tp_mc_testOnSc(2,1,:,[16,18,17]) ) );

%%

boxplot_performance( ...
    'mc&sc train&test;all classes;all fcs;all algs;eq&neq',...
    {'iso sc lasso-fs1', 'iso sc lasso-fs3', 'iso sc svm-O', 'iso sc svm-fs1', 'iso sc svm-fs3',...
     'iso mc lasso-fs1', 'iso mc lasso-fs3', 'iso mc svm-O', 'iso mc svm-fs1', 'iso mc svm-fs3',...
     'cross sc lasso-fs1', 'cross sc lasso-fs3','cross sc svm-fs1',...
     'cross mc lasso-fs1', 'cross mc lasso-fs3','cross mc svm-fs1'},...
    [tp_sc{1,:,:,:,1}], [tp_sc{2,:,:,:,1}], [tp_sc{3,:,:,:,1}], [tp_sc{4,:,:,:,1}], [tp_sc{5,:,:,:,1}], ...
    [tp_mc{1,:,:}],[tp_mc{2,:,:}],[tp_mc{3,:,:}],[tp_mc{4,:,:}],[tp_mc{5,:,:}],...
    [tp_sc{1,:,:,:,2}], [tp_sc{2,:,:,:,2}], [tp_sc{4,:,:,:,2}], ...
    [tp_mc_testOnSc{1,:,:,10:18}],[tp_mc_testOnSc{2,:,:,10:18}],[tp_mc_testOnSc{4,:,:,10:18}]...
    );

%%

boxplot_performance( ...
    'mc&sc train&test;by classes;all fcs;svm-fs1;eq&neq',...
    {'iso sc alarm', 'iso mc alarm', 'cross sc alarm', 'cross mc alarm', ...
     'iso sc baby', 'iso mc baby', 'cross sc baby', 'cross mc baby',...
     'iso sc female', 'iso mc female', 'cross sc female', 'cross mc female',...
     'iso sc fire', 'iso mc fire', 'cross sc fire', 'cross mc fire'},...
    [tp_sc{4,:,1,:,1}], [tp_mc{4,:,1}], [tp_sc{4,:,1,:,2}], [tp_mc_testOnSc{4,:,1,10:18}], ...
    [tp_sc{4,:,2,:,1}], [tp_mc{4,:,2}], [tp_sc{4,:,2,:,2}], [tp_mc_testOnSc{4,:,2,10:18}],...
    [tp_sc{4,:,3,:,1}], [tp_mc{4,:,3}], [tp_sc{4,:,3,:,2}], [tp_mc_testOnSc{4,:,3,10:18}], ...
    [tp_sc{4,:,4,:,1}], [tp_mc{4,:,4}], [tp_sc{4,:,4,:,2}], [tp_mc_testOnSc{4,:,4,10:18}]...
    );

%%

boxplot_performance( ...
    'mc&sc train&test;by classes;all fcs;lasso-fs1;eq&neq',...
    {'iso sc alarm', 'iso mc alarm', 'cross sc alarm', 'cross mc alarm', ...
     'iso sc baby', 'iso mc baby', 'cross sc baby', 'cross mc baby',...
     'iso sc female', 'iso mc female', 'cross sc female', 'cross mc female',...
     'iso sc fire', 'iso mc fire', 'cross sc fire', 'cross mc fire'},...
    [tp_sc{1,:,1,:,1}], [tp_mc{1,:,1}], [tp_sc{1,:,1,:,2}], [tp_mc_testOnSc{1,:,1,10:18}], ...
    [tp_sc{1,:,2,:,1}], [tp_mc{1,:,2}], [tp_sc{1,:,2,:,2}], [tp_mc_testOnSc{1,:,2,10:18}],...
    [tp_sc{1,:,3,:,1}], [tp_mc{1,:,3}], [tp_sc{1,:,3,:,2}], [tp_mc_testOnSc{1,:,3,10:18}], ...
    [tp_sc{1,:,4,:,1}], [tp_mc{1,:,4}], [tp_sc{1,:,4,:,2}], [tp_mc_testOnSc{1,:,4,10:18}]...
    );


