function results_directionality

tp_mc = cell(5,3,4); % alg, fc, class
tp_mc_testOnSc = cell(5,3,4,18); % alg, fc, class, testSc
tp_sc = cell(5,4,4,3,2); % alg, fc, class, scGrp, eqOrNeq
tp_sc_azm = cell(5,4,4,3,2,4); % alg, fc, class, scGrp, eqOrNeq, teAzmGrp
tp_sc_azmDist = cell(5,4,4,3,5); % alg, fc, class, scGrp, trTeAzmDist(0,45,90,135,180)
tp_sc_azmGos = cell(5,4,4,3,2,3); % alg, fc, class, scGrp, eqOrNeq, teAzmGrp
tp_sc_azmSepGos_snrs = cell(5,4,4,2,4); % alg, fc, class, eqOrNeq, teSnrGrp

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
azms = [0,45,90,180];
azmsDists = [0,45,90,135,180];
for ii = 1 : 4, for jj = 1 : 4, for ff = 1 : 2, for cc = 1 : 4
    azmdist = abs( azms(ii) - azms(jj) );
    azmdistIdx = find( azmsDists == azmdist );
    if ii == jj
        tp_sc{1,ff,cc,1,1} = [tp_sc{1,ff,cc,1,1} test_performances_b{:,cc,ff,ii,ii}];
        tp_sc{2,ff,cc,1,1} = [tp_sc{2,ff,cc,1,1} test_performances_hws{:,cc,ff,ii,ii}];
        tp_sc_azm{1,ff,cc,1,1,ii} = [tp_sc_azm{1,ff,cc,1,1,ii} test_performances_b{:,cc,ff,ii,ii}];
        tp_sc_azm{2,ff,cc,1,1,ii} = [tp_sc_azm{2,ff,cc,1,1,ii} test_performances_hws{:,cc,ff,ii,ii}];
    else
        tp_sc{1,ff,cc,1,2} = [tp_sc{1,ff,cc,1,2} test_performances_b{:,cc,ff,ii,jj}];
        tp_sc{2,ff,cc,1,2} = [tp_sc{2,ff,cc,1,2} test_performances_hws{:,cc,ff,ii,jj}];
        tp_sc_azm{1,ff,cc,1,2,jj} = [tp_sc_azm{1,ff,cc,1,2,jj} test_performances_b{:,cc,ff,ii,jj}];
        tp_sc_azm{2,ff,cc,1,2,jj} = [tp_sc_azm{2,ff,cc,1,2,jj} test_performances_hws{:,cc,ff,ii,jj}];
    end
    tp_sc_azmDist{1,ff,cc,1,azmdistIdx} = [tp_sc_azmDist{1,ff,cc,1,azmdistIdx} test_performances_b{:,cc,ff,ii,jj}];
    tp_sc_azmDist{2,ff,cc,1,azmdistIdx} = [tp_sc_azmDist{2,ff,cc,1,azmdistIdx} test_performances_hws{:,cc,ff,ii,jj}];
    tp_sc{1,ff,cc,1,1} = tp_sc{1,ff,cc,1,1}(:)';
    tp_sc{1,ff,cc,1,2} = tp_sc{1,ff,cc,1,2}(:)';
    tp_sc{2,ff,cc,1,1} = tp_sc{2,ff,cc,1,1}(:)';
    tp_sc{2,ff,cc,1,2} = tp_sc{2,ff,cc,1,2}(:)';
end; end; end; end;

%% 'glmnet_azms_' classes{cc} '_svm.mat'
classes = {'alarm', 'baby', 'femaleSpeech', 'fire'};
for cc = 1 : 4
load(['glmnet_azms_' classes{cc} '_svm.mat']);

for ii = 1 : 4, for jj = 1 : 4, for ff = 1 : 2
azmdist = abs( azms(ii) - azms(jj) );
azmdistIdx = find( azmsDists == azmdist );
for ll = 1 : 3
    if ii == jj
        tp_sc{2+ll,ff,cc,1,1} = [tp_sc{2+ll,ff,cc,1,1} test_performances{:,ll,ff,ii,ii}];
        tp_sc_azm{2+ll,ff,cc,1,1,ii} = [tp_sc_azm{2+ll,ff,cc,1,1,ii} test_performances{:,ll,ff,ii,ii}];
    else
        tp_sc{2+ll,ff,cc,1,2} = [tp_sc{2+ll,ff,cc,1,2} test_performances{:,ll,ff,ii,jj}];
        tp_sc_azm{2+ll,ff,cc,1,2,ii} = [tp_sc_azm{2+ll,ff,cc,1,2,ii} test_performances{:,ll,ff,ii,jj}];
    end
    tp_sc_azmDist{2+ll,ff,cc,1,azmdistIdx} = [tp_sc_azmDist{2+ll,ff,cc,1,azmdistIdx} test_performances{:,ll,ff,ii,jj}];
    tp_sc_azmDist{2+ll,ff,cc,1,azmdistIdx} = [tp_sc_azmDist{2+ll,ff,cc,1,azmdistIdx} test_performances{:,ll,ff,ii,jj}];
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
        tp_sc_azmGos{1,ff,cc,2,1,ii} = [tp_sc_azmGos{1,ff,cc,2,1,ii} test_performances_b{kk,ff,ii,ii,kk}];
        tp_sc_azmGos{2,ff,cc,2,1,ii} = [tp_sc_azmGos{2,ff,cc,2,1,ii} test_performances_hws{kk,ff,ii,ii,kk}];
        if ii > 1
            tp_sc_azmSepGos_snrs{1,ff,cc,1,mm} = [tp_sc_azmSepGos_snrs{1,ff,cc,1,mm} test_performances_b{kk,ff,ii,ii,kk}];
            tp_sc_azmSepGos_snrs{2,ff,cc,1,mm} = [tp_sc_azmSepGos_snrs{2,ff,cc,1,mm} test_performances_hws{kk,ff,ii,ii,kk}];
        end
    else
        tp_sc{1,ff,cc,2,2} = [tp_sc{1,ff,cc,2,2} test_performances_b{kk,ff,ii,jj,mm}];
        tp_sc{2,ff,cc,2,2} = [tp_sc{2,ff,cc,2,2} test_performances_hws{kk,ff,ii,jj,mm}];
    end
    if ii ~= jj  && kk == mm
        tp_sc_azmGos{1,ff,cc,2,2,jj} = [tp_sc_azmGos{1,ff,cc,2,2,jj} test_performances_b{kk,ff,ii,jj,mm}];
        tp_sc_azmGos{2,ff,cc,2,2,jj} = [tp_sc_azmGos{2,ff,cc,2,2,jj} test_performances_hws{kk,ff,ii,jj,mm}];
    end
    if ii == jj  && kk ~= mm && ii > 1
        tp_sc_azmSepGos_snrs{1,ff,cc,2,mm} = [tp_sc_azmSepGos_snrs{1,ff,cc,2,mm} test_performances_b{kk,ff,ii,ii,mm}];
        tp_sc_azmSepGos_snrs{2,ff,cc,2,mm} = [tp_sc_azmSepGos_snrs{2,ff,cc,2,mm} test_performances_hws{kk,ff,ii,ii,mm}];
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
        tp_sc_azmGos{2+ll,ff,cc,2,1,ii} = [tp_sc_azmGos{2+ll,ff,cc,2,1,ii} test_performances{kk,ll,ff,ii,jj,mm}];
        if ii > 1
            tp_sc_azmSepGos_snrs{2+ll,ff,cc,1,mm} = ...
                [tp_sc_azmSepGos_snrs{2+ll,ff,cc,1,mm} test_performances{kk,ll,ff,ii,jj,mm}];
        end
    else
        tp_sc{2+ll,ff,cc,2,2} = [tp_sc{2+ll,ff,cc,2,2} test_performances{kk,ll,ff,ii,jj,mm}];
    end
    if ii ~= jj  && kk == mm
        tp_sc_azmGos{2+ll,ff,cc,2,2,jj} = [tp_sc_azmGos{2+ll,ff,cc,2,2,jj} test_performances{kk,ll,ff,ii,jj,mm}];
    end
    if ii == jj  && kk ~= mm && ii > 1
        tp_sc_azmSepGos_snrs{2+ll,ff,cc,2,mm} = ...
            [tp_sc_azmSepGos_snrs{2+ll,ff,cc,2,mm} test_performances{kk,ll,ff,ii,jj,mm}];
    end
end
end; end;
end; end; end;
end


%% 

boxplot_performance( ...
    'no iso difference between bin and mon',...
    {'0°','45°', '90°', '180°'},...
     ...%'sc mon iso 0°','sc mon iso 45°', 'sc mon iso 90°', 'sc mon iso 180°'},...
     [],...%1 1 1 1 2 2 2 2],...
     [tp_sc_azm{:,1,:,1,1,1}],[tp_sc_azm{:,1,:,1,1,2}], ...
     [tp_sc_azm{:,1,:,1,1,3}],[tp_sc_azm{:,1,:,1,1,4}] );%, ...
%      [tp_sc_azm{:,2,:,1,1,1}],[tp_sc_azm{:,2,:,1,1,2}], ...
%      [tp_sc_azm{:,2,:,1,1,3}],[tp_sc_azm{:,2,:,1,1,4}]);
xlabel( 'azimuth of target' );

% %% 
% 
% boxplot_performance( ...
%     'slight cross advantage for mon over bin',...
%     {'sc bin cross 0°','sc bin cross 45°', 'sc bin cross 90°', 'sc bin cross 180°',...
%      'sc mon cross 0°','sc mon cross 45°', 'sc mon cross 90°', 'sc mon cross 180°'},...
%      [1 1 1 1 2 2 2 2],...
%      [tp_sc_azm{:,1,:,1,2,1}],[tp_sc_azm{:,1,:,1,2,2}], ...
%      [tp_sc_azm{:,1,:,1,2,3}],[tp_sc_azm{:,1,:,1,2,4}], ...
%      [tp_sc_azm{:,2,:,1,2,1}],[tp_sc_azm{:,2,:,1,2,2}], ...
%      [tp_sc_azm{:,2,:,1,2,3}],[tp_sc_azm{:,2,:,1,2,4}]);


%% 

boxplot_performance( ...
    'azm difference train and test',...
    {'0°','45°', '90°', '135°', '180°'},...
     ...%'Monaural 0°','Monaural 45°', 'Monaural 90°', 'Monaural 135°', 'Monaural 180°'},...
     [],...%1 1 1 1 1 2 2 2 2 2],...
     [tp_sc_azmDist{:,1,:,1,1}],[tp_sc_azmDist{:,1,:,1,2}], ...
     [tp_sc_azmDist{:,1,:,1,3}],[tp_sc_azmDist{:,1,:,1,4}],[tp_sc_azmDist{:,1,:,1,5}] );%, ...
%      [tp_sc_azmDist{:,2,:,1,1}],[tp_sc_azmDist{:,2,:,1,2}], ...
%      [tp_sc_azmDist{:,2,:,1,3}],[tp_sc_azmDist{:,2,:,1,4}],[tp_sc_azmDist{:,2,:,1,5}]);
xlabel( 'azimuth difference between training and testing' );

%% 

% boxplot_performance( ...
%     'GO: iso advantage for bin over mon',...
%     {'sc bin iso 0°-0°','sc bin iso +45°-45°', 'sc bin iso +90°-90°',...
%      'sc mon iso 0°-0°','sc mon iso +45°-45°', 'sc mon iso +90°-90°'},...
%      [1 1 1 2 2 2],...
%      [tp_sc_azmGos{:,1,:,2,1,1}],[tp_sc_azmGos{:,1,:,2,1,2}], ...
%      [tp_sc_azmGos{:,1,:,2,1,3}],[tp_sc_azmGos{:,2,:,2,1,1}], ...
%      [tp_sc_azmGos{:,2,:,2,1,2}],[tp_sc_azmGos{:,2,:,2,1,3}] );
% 
%% 

% boxplot_performance( ...
%     'GO: iso advantage for bin over mon for separated objects',...
%     {'sc bin iso +90°-90° & +45°-45°',...
%      'sc mon iso +90°-90° & +45°-45°'},...
%      [],...
%      [tp_sc_azmGos{:,1,:,2,1,2:3}], ...
%      [tp_sc_azmGos{:,2,:,2,1,2:3}] );
% 
%% 

boxplot_performance( ...
    'GO: iso advantage by dB for bin over mon for separated objects',...
    {'Binaural 20dB','Monaural 20dB','Binaural 10dB','Monaural 10dB'...
     'Binaural 0dB','Monaural 0dB','Binaural -10dB','Monaural -10dB'},...
     [1 2 1 2 1 2 1 2],...
     [tp_sc_azmSepGos_snrs{:,1,:,1,1}],[tp_sc_azmSepGos_snrs{:,2,:,1,1}],...
     [tp_sc_azmSepGos_snrs{:,1,:,1,2}],[tp_sc_azmSepGos_snrs{:,2,:,1,2}], ...
     [tp_sc_azmSepGos_snrs{:,1,:,1,3}],[tp_sc_azmSepGos_snrs{:,2,:,1,3}],...
     [tp_sc_azmSepGos_snrs{:,1,:,1,4}],[tp_sc_azmSepGos_snrs{:,2,:,1,4}] );

%% 

% boxplot_performance( ...
%     'GO: cross-snr difference by dB for bin over mon for separated objects',...
%     {'sc bin cross sep 20dB','sc mon cross sep 20dB','sc bin cross sep 10dB','sc mon cross sep 10dB'...
%      'sc bin cross sep 0dB','sc mon cross sep 0dB','sc bin cross sep -10dB','sc mon cross sep -10dB'},...
%      [1 2 1 2 1 2 1 2],...
%      [tp_sc_azmSepGos_snrs{:,1,:,2,1}],[tp_sc_azmSepGos_snrs{:,2,:,2,1}],...
%      [tp_sc_azmSepGos_snrs{:,1,:,2,2}],[tp_sc_azmSepGos_snrs{:,2,:,2,2}], ...
%      [tp_sc_azmSepGos_snrs{:,1,:,2,3}],[tp_sc_azmSepGos_snrs{:,2,:,2,3}],...
%      [tp_sc_azmSepGos_snrs{:,1,:,2,4}],[tp_sc_azmSepGos_snrs{:,2,:,2,4}] );
% 
%  
%  
%  
 
 
 
 
 
 