function make_results_PDs_mc_sc

tp_mc_sc_iso = cell(11,3,4,2,19); % class, dd, ss, ff, aa

% 'pds_glmnet_test.mat'
tb1 = load('pds_glmnet_mc_sc_1_test.mat', 'test_performances_b');
tb2 = load('pds_glmnet_mc_sc_2_test.mat', 'test_performances_b');
tb3 = load('pds_glmnet_mc_sc_3_test.mat', 'test_performances_b');
tb4 = load('pds_glmnet_mc_sc_4_test.mat', 'test_performances_b');
tb511 = load('pds_glmnet_mc_sc_5___6___7___8___9__10__11_test.mat', 'test_performances_b');

tb(1,:,:,:,:) = tb1.test_performances_b(1,:,:,:,:);
tb(2,:,:,:,:) = tb2.test_performances_b(2,:,:,:,:);
tb(3,:,:,:,:) = tb3.test_performances_b(3,:,:,:,:);
tb(4,:,:,:,:) = tb4.test_performances_b(4,:,:,:,:);
tb(5:11,:,:,:,:) = tb511.test_performances_b(5:11,:,:,:,:);
tb(:,[1,3,5],:,:,:) = [];
tb = permute( tb, [1,2,4,3] );
tp_mc_sc_iso(:,:,:,1,:) = tb;

classes = {'alarm','baby','femaleSpeech','fire','crash','dog','engine','footsteps',...
           'knock','phone','piano'};

% %%
% boxplot_performance( ...
%     'pairwise difference between datasets',...
%     {'d1 - d2','d1 - d3', 'd2 - d3'},...
%     [],...
%     {'notch', 'off', 'widths', 0.8},...
%     [tp_mc_sc_iso{:,1,:,:,:}] - [tp_mc_sc_iso{:,2,:,:,:}], ...
%     [tp_mc_sc_iso{:,1,:,:,:}] - [tp_mc_sc_iso{:,3,:,:,:}], ...
%     [tp_mc_sc_iso{:,2,:,:,:}] - [tp_mc_sc_iso{:,3,:,:,:}] ...
%     );
% ylim( [-0.3 0.3] );
%  
% %% 
% boxplot_performance( ...
%     'class performance. all dd, ss, ff, aa',...
%     classes,...
%     [],...
%     [],...
%     [tp_mc_sc_iso{1,:,:,:,:}],[tp_mc_sc_iso{2,:,:,:,:}], ...
%     [tp_mc_sc_iso{3,:,:,:,:}],[tp_mc_sc_iso{4,:,:,:,:}], ...
%     [tp_mc_sc_iso{5,:,:,:,:}],[tp_mc_sc_iso{6,:,:,:,:}], ...
%     [tp_mc_sc_iso{7,:,:,:,:}],[tp_mc_sc_iso{8,:,:,:,:}], ...
%     [tp_mc_sc_iso{9,:,:,:,:}],[tp_mc_sc_iso{10,:,:,:,:}],[tp_mc_sc_iso{11,:,:,:,:}] );
% 
%% 
figure( 'Name', 'test performance by class and SNR. all dd, ff, aa' );

for ii = 1 : 11

subplot( 2, 6, ii );
boxplot_grps( ...
    {'10 dB','0 dB','-10 dB','-20 dB'}, [], [],...
    [tp_mc_sc_iso{ii,:,3,:,:}],[tp_mc_sc_iso{ii,:,1,:,:}],...
    [tp_mc_sc_iso{ii,:,2,:,:}],[tp_mc_sc_iso{ii,:,4,:,:}] );
ylim([0.5,1]);
title( classes{ii} );

end

% %%
% aaorder = [1 3 4 2 5 6 14 10 9 8 7 11 12 13 15 16 17 18 19];
% labels = {'0(0)',...
%           '-45(0)','-22.5(22.5)','0(45)','67.5(112.5)','157.5(202.5)',...
%           '157.5(247.5)','90(180)','45(135)','22.5(112.5)','0(90)','-22.5(67.5)','-45(45)','-90(0)',...
%           '0(180)','22.5(-157.5)','45(-135)','67.5(-112.5)','90(-90)'};
% 
% %
% % data = {};
% % for ii = 1:19
% %     data{ii} = [tp_sc_iso{:,:,:,:,aaorder(ii)}];
% % end
% % boxplot_performance( ...
% %     'aa performance. all dd, cc, ss, ff',...
% %     labels,...
% %     [1 2 2 2 2 2 3 3 3 3 3 3 3 3 4 4 4 4 4],...
% %     [],...
% %     data{:} );
% 
% % data = {};
% % for ii = 1:19
% %     data{ii} = [tp_sc_iso{:,:,:,1,aaorder(ii)}];
% % end
% % boxplot_performance( ...
% %     'aa Monaural performance. all dd, cc, ss.',...
% %     labels,...
% %     [1 2 2 2 2 2 3 3 3 3 3 3 3 3 4 4 4 4 4],...
% %     [],...
% %     data{:} );
% % 
% % data = {};
% % for ii = 1:19
% %     data{ii} = [tp_sc_iso{:,:,:,2,aaorder(ii)}];
% % end
% % boxplot_performance( ...
% %     'aa Binaural performance. all dd, cc, ss',...
% %     labels,...
% %     [1 2 2 2 2 2 3 3 3 3 3 3 3 3 4 4 4 4 4],...
% %     [],...
% %     data{:} );
% 
% % data = {};
% % for ii = 1:19
% %     data{ii} = [tp_sc_iso{:,:,[2,4],1,aaorder(ii)}];
% % end
% % boxplot_performance( ...
% %     'aa Monaural strong noise performance. all dd, cc',...
% %     labels,...
% %     [1 2 2 2 2 2 3 3 3 3 3 3 3 3 4 4 4 4 4],...
% %     [],...
% %     data{:} );
% % 
% % data = {};
% % for ii = 1:19
% %     data{ii} = [tp_sc_iso{:,:,[2,4],2,aaorder(ii)}];
% % end
% % boxplot_performance( ...
% %     'aa Binaural strong noise performance. all dd, cc',...
% %     labels,...
% %     [1 2 2 2 2 2 3 3 3 3 3 3 3 3 4 4 4 4 4],...
% %     [],...
% %     data{:} );
% % 
% % data = {};
% % for ii = 1:19
% %     data{ii} = [tp_sc_iso{:,:,3,1,aaorder(ii)}];
% % end
% % boxplot_performance( ...
% %     'aa Monaural low noise performance. all dd, cc',...
% %     labels,...
% %     [1 2 2 2 2 2 3 3 3 3 3 3 3 3 4 4 4 4 4],...
% %     [],...
% %     data{:} );
% 
% % data = {};
% % for ii = 1:19
% %     data{ii} = [tp_sc_iso{:,:,3,2,aaorder(ii)}];
% % end
% % boxplot_performance( ...
% %     'aa Binaural low noise performance. all dd, cc',...
% %     labels,...
% %     [1 2 2 2 2 2 3 3 3 3 3 3 3 3 4 4 4 4 4],...
% %     [],...
% %     data{:} );
% 
% %%
% data10db = {};
% for ii = 1:19
%     data10db{ii} = [tp_mc_sc_iso{:,:,3,2,aaorder(ii)}];
% end
% data0db = {};
% for ii = 1:19
%     data0db{ii} = [tp_mc_sc_iso{:,:,1,2,aaorder(ii)}];
% end
% dataM10db = {};
% for ii = 1:19
%     dataM10db{ii} = [tp_mc_sc_iso{:,:,2,2,aaorder(ii)}];
% end
% dataM20db = {};
% for ii = 1:19
%     dataM20db{ii} = [tp_mc_sc_iso{:,:,4,2,aaorder(ii)}];
% end
% 
% %%
% figure;
% set( gcf, 'Name', '45° azm diff Binaural performance. mean over all dd, cc' );
% hold all;
% 
% meanplot_performance( '10 dB',...
%     labels(6:-1:2), [], data10db{6:-1:2} );
% 
% meanplot_performance( '0 dB',...
%     labels(6:-1:2), [], data0db{6:-1:2} );
% 
% meanplot_performance( '-10 dB',...
%     labels(6:-1:2), [], dataM10db{6:-1:2} );
% 
% meanplot_performance( '-20 dB',...
%     labels(6:-1:2), [], dataM20db{6:-1:2} );
% 
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% %%
% figure;
% set( gcf, 'Name', '90° azm diff Binaural performance. mean over all dd, cc' );
% hold all;
% 
% meanplot_performance( '10 dB',...
%     labels(14:-1:7), [], data10db{14:-1:7} );
% 
% meanplot_performance( '0 dB',...
%     labels(14:-1:7), [], data0db{14:-1:7} );
% 
% meanplot_performance( '-10 dB',...
%     labels(14:-1:7), [], dataM10db{14:-1:7} );
% 
% meanplot_performance( '-20 dB',...
%     labels(14:-1:7), [], dataM20db{14:-1:7} );
% 
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% %%
% figure;
% set( gcf, 'Name', '180° azm diff Binaural performance. mean over all dd, cc' );
% hold all;
% 
% meanplot_performance( '10 dB',...
%     labels(15:19), [], data10db{15:19} );
% 
% meanplot_performance( '0 dB',...
%     labels(15:19), [], data0db{15:19} );
% 
% meanplot_performance( '-10 dB',...
%     labels(15:19), [], dataM10db{15:19} );
% 
% meanplot_performance( '-20 dB',...
%     labels(15:19), [], dataM20db{15:19} );
% 
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% %%
% dataMdbAlarm = {};
% for ii = 1:19
%     dataMdbAlarm{ii} = [tp_mc_sc_iso{1,:,[2,4],2,aaorder(ii)}];
% end
% dataMdbBaby = {};
% for ii = 1:19
%     dataMdbBaby{ii} = [tp_mc_sc_iso{2,:,[2,4],2,aaorder(ii)}];
% end
% dataMdbFemale = {};
% for ii = 1:19
%     dataMdbFemale{ii} = [tp_mc_sc_iso{3,:,[2,4],2,aaorder(ii)}];
% end
% dataMdbFire = {};
% for ii = 1:19
%     dataMdbFire{ii} = [tp_mc_sc_iso{4,:,[2,4],2,aaorder(ii)}];
% end
% 
% %%
% figure;
% set( gcf, 'Name', '45° azm diff Binaural strong noise performance. mean over all dd' );
% hold all;
% 
% meanplot_performance( 'Alarm',...
%     labels(6:-1:2), [], dataMdbAlarm{6:-1:2} );
% 
% meanplot_performance( 'Baby',...
%     labels(6:-1:2), [], dataMdbBaby{6:-1:2} );
% 
% meanplot_performance( 'Female',...
%     labels(6:-1:2), [], dataMdbFemale{6:-1:2} );
% 
% meanplot_performance( 'Fire',...
%     labels(6:-1:2), [], dataMdbFire{6:-1:2} );
% 
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% %%
% figure;
% set( gcf, 'Name', '90° azm diff Binaural strong noise performance. mean over all dd' );
% hold all;
% 
% meanplot_performance( 'Alarm',...
%     labels(14:-1:7), [], dataMdbAlarm{14:-1:7} );
% 
% meanplot_performance( 'Baby',...
%     labels(14:-1:7), [], dataMdbBaby{14:-1:7} );
% 
% meanplot_performance( 'Female',...
%     labels(14:-1:7), [], dataMdbFemale{14:-1:7} );
% 
% meanplot_performance( 'Fire',...
%     labels(14:-1:7), [], dataMdbFire{14:-1:7} );
% 
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% %%
% figure;
% set( gcf, 'Name', '180° azm diff Binaural strong noise performance. mean over all dd' );
% hold all;
% 
% meanplot_performance( 'Alarm',...
%     labels(15:19), [], dataMdbAlarm{15:19} );
% 
% meanplot_performance( 'Baby',...
%     labels(15:19), [], dataMdbBaby{15:19} );
% 
% meanplot_performance( 'Female',...
%     labels(15:19), [], dataMdbFemale{15:19} );
% 
% meanplot_performance( 'Fire',...
%     labels(15:19), [], dataMdbFire{15:19} );
% 
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% 
% %
% data = {};
% for ii = 1:19
%     data{ii} = [tp_mc_sc_iso{:,:,:,2,aaorder(ii)}];
% end
% datam = cellfun( @mean, data );
% data10dB = {};
% for ii = 1:19
%     data10dB{ii} = [tp_mc_sc_iso{:,:,3,2,aaorder(ii)}];
% end
% datam10dB = cellfun( @mean, data10dB );
% dataM20dB = {};
% for ii = 1:19
%     dataM20dB{ii} = [tp_mc_sc_iso{:,:,4,2,aaorder(ii)}];
% end
% datamM20dB = cellfun( @mean, dataM20dB );
% 
% dataMon = {};
% for ii = 1:19
%     dataMon{ii} = [tp_mc_sc_iso{:,:,:,1,aaorder(ii)}];
% end
% dataMonm = cellfun( @mean, dataMon );
% data10dBMon = {};
% for ii = 1:19
%     data10dBMon{ii} = [tp_mc_sc_iso{:,:,3,1,aaorder(ii)}];
% end
% datam10dBMon = cellfun( @mean, data10dBMon );
% dataM20dBMon = {};
% for ii = 1:19
%     dataM20dBMon{ii} = [tp_mc_sc_iso{:,:,4,1,aaorder(ii)}];
% end
% datamM20dBMon = cellfun( @mean, dataM20dBMon );
% 
% %
% figure;
% set( gcf, 'Name', 'azm dependent performance. mean over all dd, cc, aa, ss' );
% 
% subplot(1,2,1);
% hold all;
% 
% plot( [-90, 180], [datam(1) datam(1)], 'DisplayName', '0° spread', 'LineWidth', 2 );
% plot( [-45, -22.5, 0, 67.5, 157.5],...
%       datam(2:6),...
%       'DisplayName', '45° spread', 'LineWidth', 2 );
% plot( [-90,-45,-22.5,0,22.5,45,90,157.5],...
%       datam(14:-1:7),...
%       'DisplayName', '90° spread', 'LineWidth', 2 );
% plot( [-90, -67.5, -45, -22.5 0, 22.5, 45, 67.5, 90],...
%       [datam(19:-1:16), datam(15:19)],...
%       'DisplayName', '180° spread', 'LineWidth', 2 );
% 
% set( gca, 'XTick', -180:22.5:180,...
%           'XTickLabel', arrayfun(@num2str, -180:22.5:180, 'UniformOutput', false) );
% 
% ylabel( 'test performance' );
% set( gca,'YGrid','on' );
% xlabel( 'target azimuth (distractor put x° clockwise)' );
% title( 'Binaural' );
% ylim([0.75 0.9]);
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% subplot(1,2,2);
% hold all;
% 
% plot( [-90, 180], [dataMonm(1) dataMonm(1)], 'DisplayName', '0° spread', 'LineWidth', 2 );
% plot( [-45, -22.5, 0, 67.5, 157.5],...
%       dataMonm(2:6),...
%       'DisplayName', '45° spread', 'LineWidth', 2 );
% plot( [-90,-45,-22.5,0,22.5,45,90,157.5],...
%       dataMonm(14:-1:7),...
%       'DisplayName', '90° spread', 'LineWidth', 2 );
% plot( [-90, -67.5, -45, -22.5 0, 22.5, 45, 67.5, 90],...
%       [dataMonm(19:-1:16), dataMonm(15:19)],...
%       'DisplayName', '180° spread', 'LineWidth', 2 );
% 
% set( gca, 'XTick', -180:22.5:180,...
%           'XTickLabel', arrayfun(@num2str, -180:22.5:180, 'UniformOutput', false) );
% 
% ylabel( 'test performance' );
% set( gca,'YGrid','on' );
% xlabel( 'target azimuth (distractor put x° clockwise)' );
% title( 'Monaural' );
% ylim([0.75 0.9]);
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% %
% figure;
% set( gcf, 'Name', 'azm dependent performance. mean over all dd, cc, aa' );
% 
% subplot(2,2,1);
% hold all;
% 
% plot( [-90, 180], [datam10dB(1) datam10dB(1)], 'DisplayName', '0° spread', 'LineWidth', 2 );
% plot( [-45, -22.5, 0, 67.5, 157.5],...
%       datam10dB(2:6),...
%       'DisplayName', '45° spread', 'LineWidth', 2 );
% plot( [-90,-45,-22.5,0,22.5,45,90,157.5],...
%       datam10dB(14:-1:7),...
%       'DisplayName', '90° spread', 'LineWidth', 2 );
% plot( [-90, -67.5, -45, -22.5 0, 22.5, 45, 67.5, 90],...
%       [datam10dB(19:-1:16), datam10dB(15:19)],...
%       'DisplayName', '180° spread', 'LineWidth', 2 );
% 
% set( gca, 'XTick', -180:22.5:180,...
%           'XTickLabel', arrayfun(@num2str, -180:22.5:180, 'UniformOutput', false) );
% 
% ylabel( 'test performance' );
% set( gca,'YGrid','on' );
% xlabel( 'target azimuth (distractor put x° clockwise)' );
% title( 'Binaural, 10 dB SNR' );
% ylim([0.9 0.96]);
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% subplot(2,2,2);
% hold all;
% 
% plot( [-90, 180], [datam10dBMon(1) datam10dBMon(1)], 'DisplayName', '0° spread', 'LineWidth', 2 );
% plot( [-45, -22.5, 0, 67.5, 157.5],...
%       datam10dBMon(2:6),...
%       'DisplayName', '45° spread', 'LineWidth', 2 );
% plot( [-90,-45,-22.5,0,22.5,45,90,157.5],...
%       datam10dBMon(14:-1:7),...
%       'DisplayName', '90° spread', 'LineWidth', 2 );
% plot( [-90, -67.5, -45, -22.5 0, 22.5, 45, 67.5, 90],...
%       [datam10dBMon(19:-1:16), datam10dBMon(15:19)],...
%       'DisplayName', '180° spread', 'LineWidth', 2 );
% 
% set( gca, 'XTick', -180:22.5:180,...
%           'XTickLabel', arrayfun(@num2str, -180:22.5:180, 'UniformOutput', false) );
% 
% ylabel( 'test performance' );
% set( gca,'YGrid','on' );
% xlabel( 'target azimuth (distractor put x° clockwise)' );
% title( 'Monaural, 10 dB SNR' );
% ylim([0.9 0.96]);
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% subplot(2,2,3);
% hold all;
% 
% plot( [-90, 180], [datamM20dB(1) datamM20dB(1)], 'DisplayName', '0° spread', 'LineWidth', 2 );
% plot( [-45, -22.5, 0, 67.5, 157.5],...
%       datamM20dB(2:6),...
%       'DisplayName', '45° spread', 'LineWidth', 2 );
% plot( [-90,-45,-22.5,0,22.5,45,90,157.5],...
%       datamM20dB(14:-1:7),...
%       'DisplayName', '90° spread', 'LineWidth', 2 );
% plot( [-90, -67.5, -45, -22.5 0, 22.5, 45, 67.5, 90],...
%       [datamM20dB(19:-1:16), datamM20dB(15:19)],...
%       'DisplayName', '180° spread', 'LineWidth', 2 );
% 
% set( gca, 'XTick', -180:22.5:180,...
%           'XTickLabel', arrayfun(@num2str, -180:22.5:180, 'UniformOutput', false) );
% 
% ylabel( 'test performance' );
% set( gca,'YGrid','on' );
% xlabel( 'target azimuth (distractor put x° clockwise)' );
% title( 'Binaural, -20 dB SNR' );
% ylim([0.62 0.8]);
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% subplot(2,2,4);
% hold all;
% 
% plot( [-90, 180], [datamM20dBMon(1) datamM20dBMon(1)], 'DisplayName', '0° spread', 'LineWidth', 2 );
% plot( [-45, -22.5, 0, 67.5, 157.5],...
%       datamM20dBMon(2:6),...
%       'DisplayName', '45° spread', 'LineWidth', 2 );
% plot( [-90,-45,-22.5,0,22.5,45,90,157.5],...
%       datamM20dBMon(14:-1:7),...
%       'DisplayName', '90° spread', 'LineWidth', 2 );
% plot( [-90, -67.5, -45, -22.5 0, 22.5, 45, 67.5, 90],...
%       [datamM20dBMon(19:-1:16), datamM20dBMon(15:19)],...
%       'DisplayName', '180° spread', 'LineWidth', 2 );
% 
% set( gca, 'XTick', -180:22.5:180,...
%           'XTickLabel', arrayfun(@num2str, -180:22.5:180, 'UniformOutput', false) );
% 
% ylabel( 'test performance' );
% set( gca,'YGrid','on' );
% xlabel( 'target azimuth (distractor put x° clockwise)' );
% title( 'Monaural, -20 dB SNR' );
% ylim([0.62 0.8]);
% rotateXLabels( gca, 60 );
% legend('show', 'Location', 'Best');
% 
% %
% noseBetweenTD = [tp_mc_sc_iso{:,:,[1,2,4],2,aaorder([3 12 13 19])}];
% backBetweenTD = [tp_mc_sc_iso{:,:,[1,2,4],2,aaorder([6 7 19])}];
% TDoneSideDcloserToNose = [tp_mc_sc_iso{:,:,[1,2,4],2,aaorder([2 14])}];
% TDoneSideTcloserToNose = [tp_mc_sc_iso{:,:,[1,2,4],2,aaorder([4 5 8 9 10 11])}];
% 
% boxplot_performance( ...
%     'Binaural test performance. all dd, cc, ss',...
%     {'Nose between T,D','Back between T,D',...
%      'T,D on one side - D closer to nose','T,D on one side - T closer to nose'},...
%     [],...
%     [],...
%     noseBetweenTD,backBetweenTD,TDoneSideDcloserToNose,TDoneSideTcloserToNose);
% 
% %
% boxplot_performance( ...
%     'target-distractor azimuth difference, ff performance. all dd, cc, ss',...
%     {'0° Monaural','0° Binaural','45° Monaural','45° Binaural',...
%      '90° Monaural','90° Binaural','180° Monaural','180° Binaural'},...
%     [1 1 2 2 3 3 4 4],...
%     [],...
%     [tp_mc_sc_iso{:,:,:,1,1}],[tp_mc_sc_iso{:,:,:,2,1}],[tp_mc_sc_iso{:,:,:,1,2:6}],[tp_mc_sc_iso{:,:,:,2,2:6}],...
%     [tp_mc_sc_iso{:,:,:,1,7:14}],[tp_mc_sc_iso{:,:,:,2,7:14}],[tp_mc_sc_iso{:,:,:,1,15:19}],[tp_mc_sc_iso{:,:,:,2,15:19}] );
% 
% 
% boxplot_performance( ...
%     'target-distractor azimuth difference, pairwise ff performance difference, strong noise. all dd, cc',...
%     {'0° Binaural - Monaural','45° Binaural - Monaural',...
%      '90° Binaural - Monaural','180° Binaural - Monaural'},...
%     [],...
%     [],...
%     [tp_mc_sc_iso{:,:,[2,4],2,1}] - [tp_mc_sc_iso{:,:,[2,4],1,1}],...
%     [tp_mc_sc_iso{:,:,[2,4],2,2:6}] - [tp_mc_sc_iso{:,:,[2,4],1,2:6}],...
%     [tp_mc_sc_iso{:,:,[2,4],2,7:14}] - [tp_mc_sc_iso{:,:,[2,4],1,7:14}],...
%     [tp_mc_sc_iso{:,:,[2,4],2,15:19}] - [tp_mc_sc_iso{:,:,[2,4],1,15:19}] );
% ylim([-0.15 0.2]);
% 
% boxplot_performance( ...
%     'target-distractor azimuth difference, pairwise ff performance difference, low noise. all dd, cc',...
%     {'0° Binaural - Monaural','45° Binaural - Monaural',...
%      '90° Binaural - Monaural','180° Binaural - Monaural'},...
%     [],...
%     [],...
%     [tp_mc_sc_iso{:,:,3,2,1}] - [tp_mc_sc_iso{:,:,3,1,1}],...
%     [tp_mc_sc_iso{:,:,3,2,2:6}] - [tp_mc_sc_iso{:,:,3,1,2:6}],...
%     [tp_mc_sc_iso{:,:,3,2,7:14}] - [tp_mc_sc_iso{:,:,3,1,7:14}],...
%     [tp_mc_sc_iso{:,:,3,2,15:19}] - [tp_mc_sc_iso{:,:,3,1,15:19}] );
% ylim([-0.15 0.2]);
% 
% 
% 
%  
%  
%  
%  
%  