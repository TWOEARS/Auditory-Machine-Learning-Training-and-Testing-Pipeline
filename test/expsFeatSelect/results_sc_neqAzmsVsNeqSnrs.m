function results_sc_neqAzmsVsNeqSnrs

tp_sc = cell(5,4,4,3,4); % alg, fc, class, scGrp, eqOrNeqAzmsOrNeqSnrsOrNeq

%% 'glmnet_gos_' classes{cc} '_test.mat'
classes = {'alarm', 'baby', 'femaleSpeech', 'fire'};
for cc = 1 : 4
load(['glmnet_gos_' classes{cc} '_test.mat']);
for ii = 1 : 3, for jj = 1 : 3, for ff = 1 : 4
for kk = 1 : 4, for mm = 1 : 4
    if ii == jj  && kk == mm
        tp_sc{1,ff,cc,2,1} = [tp_sc{1,ff,cc,2,1} test_performances_b{kk,ff,ii,ii,kk}];
    elseif ii == jj  && kk ~= mm
        tp_sc{1,ff,cc,2,3} = [tp_sc{1,ff,cc,2,3} test_performances_b{kk,ff,ii,jj,mm}];
    elseif ii ~= jj  && kk == mm
        tp_sc{1,ff,cc,2,2} = [tp_sc{1,ff,cc,2,2} test_performances_b{kk,ff,ii,jj,mm}];
    else %ii ~= jj  && kk ~= mm
        tp_sc{1,ff,cc,2,4} = [tp_sc{1,ff,cc,2,4} test_performances_b{kk,ff,ii,jj,mm}];
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
    elseif ii == jj  && kk ~= mm
        tp_sc{2+ll,ff,cc,2,3} = [tp_sc{2+ll,ff,cc,2,3} test_performances{kk,ll,ff,ii,jj,mm}];
    elseif ii ~= jj  && kk == mm
        tp_sc{2+ll,ff,cc,2,2} = [tp_sc{2+ll,ff,cc,2,2} test_performances{kk,ll,ff,ii,jj,mm}];
    else %ii ~= jj  && kk ~= mm
        tp_sc{2+ll,ff,cc,2,4} = [tp_sc{2+ll,ff,cc,2,4} test_performances{kk,ll,ff,ii,jj,mm}];
    end
end
end; end;
end; end; end;
end


%%
tp_b_eq_fc1 = [tp_sc{[1,4],1,:,:,1}];
tp_b_neqAzms_fc1 = [tp_sc{[1,4],1,:,:,2}];
tp_b_eq_fc2 = [tp_sc{[1,4],2,:,:,1}];
tp_b_neqAzms_fc2 = [tp_sc{[1,4],2,:,:,2}];
tp_b_neqSnrs_fc1 = [tp_sc{[1,4],1,:,:,3}];
tp_b_neqSnrs_fc2 = [tp_sc{[1,4],2,:,:,3}];
tp_b_neq_fc1 = [tp_sc{[1,4],1,:,:,4}];
tp_b_neq_fc2 = [tp_sc{[1,4],2,:,:,4}];

boxplot_performance( 'sc,glmnet+svm,go: neqAzms vs neqSnrs', ...
                     {'iso, binaural', 'iso, monaural', ...
                      'cross azms, binaural', 'cross azms, monaural', ...
                      'cross snrs, binaural', 'cross snrs, monaural', ...
                      'cross both, binaural', 'cross both, monaural' }, ...
                     tp_b_eq_fc1, tp_b_eq_fc2, tp_b_neqAzms_fc1,...
                     tp_b_neqAzms_fc2, tp_b_neqSnrs_fc1, tp_b_neqSnrs_fc2, ...
                     tp_b_neq_fc1, tp_b_neq_fc2 );

% add azms and dwn?
