clearAllButBreakpoints;
load('glmnet_azms_test.mat')
tp_b = cellSqueezeFun( @(cc)(mean([cc{:}])), test_performances_b, 1 );
tp_hws = cellSqueezeFun( @(cc)(mean([cc{:}])), test_performances_hws, 1 );
nc_b = cellSqueezeFun( @(cc)(mean([cc{:}])), nCoefs_b, 1 );
nc_hws = cellSqueezeFun( @(cc)(mean([cc{:}])), nCoefs_hws, 1 );

dimNames = {'class','featureCreator','trainAzm','testAzm'};
dimValues.class = {'alarm','baby','femaleSpeech','fire'};
dimValues.featureCreator = {'FeatureSet1Blockmean2Ch','FeatureSet1Blockmean'};
dimValues.trainAzm = [0,45,90,180];
dimValues.testAzm = [0,45,90,180];

load('glmnet_azms_fire_svm.mat');
tp_svm{4} = cellSqueezeFun( @(c)(mean([c{:}])), test_performances, 1 );
load('glmnet_azms_alarm_svm.mat');
tp_svm{1} = cellSqueezeFun( @(c)(mean([c{:}])), test_performances, 1 );
load('glmnet_azms_baby_svm.mat');
tp_svm{2} = cellSqueezeFun( @(c)(mean([c{:}])), test_performances, 1 );
load('glmnet_azms_femaleSpeech_svm.mat');
tp_svm{3} = cellSqueezeFun( @(c)(mean([c{:}])), test_performances, 1 );


for cc = 1 : 4
    figure('Name', [dimValues.class{cc} ' test performance, trainAzm == testAzm']);
    subplot(2,2,1);
    hold all;
    title( 'glmnet models' );
    plot( dimValues.trainAzm,...
        [tp_b(1,cc,1,1,1),tp_b(1,cc,1,2,2),tp_b(1,cc,1,3,3),tp_b(1,cc,1,4,4)],...
        '--om', 'DisplayName', 'glmnet-b binaural', 'LineWidth', 2 );
    plot( dimValues.trainAzm,...
        [tp_b(1,cc,2,1,1),tp_b(1,cc,2,2,2),tp_b(1,cc,2,3,3),tp_b(1,cc,2,4,4)],...
        ':*m', 'DisplayName', 'glmnet-b monaural', 'LineWidth', 2 );
    plot( dimValues.trainAzm,...
        [tp_hws(1,cc,1,1,1),tp_hws(1,cc,1,2,2),tp_hws(1,cc,1,3,3),tp_hws(1,cc,1,4,4)],...
        '--oc', 'DisplayName', 'glmnet-hws binaural' );
    plot( dimValues.trainAzm,...
        [tp_hws(1,cc,2,1,1),tp_hws(1,cc,2,2,2),tp_hws(1,cc,2,3,3),tp_hws(1,cc,2,4,4)],...
        ':*c', 'DisplayName', 'glmnet-hws monaural' );
    legend('show');
    subplot(2,2,2);
    hold all;
    title( 'best glmnet & svm' );
    plot( dimValues.trainAzm,...
        [tp_b(1,cc,1,1,1),tp_b(1,cc,1,2,2),tp_b(1,cc,1,3,3),tp_b(1,cc,1,4,4)],...
        '--om', 'DisplayName', 'glmnet-b binaural', 'LineWidth', 2 );
    plot( dimValues.trainAzm,...
        [tp_b(1,cc,2,1,1),tp_b(1,cc,2,2,2),tp_b(1,cc,2,3,3),tp_b(1,cc,2,4,4)],...
        ':*m', 'DisplayName', 'glmnet-b monaural', 'LineWidth', 2 );
    ta = [];
    tap = {};
    for ii = 1 : 4
        if size( tp_svm{cc}, 4 ) >= ii  &&  size( tp_svm{cc}, 5 ) >= ii 
            ta(end+1) = dimValues.trainAzm(ii);
            tap{1,end+1} = tp_svm{cc}(1,1,1,ii,ii);
            tap{2,end} = tp_svm{cc}(1,2,1,ii,ii);
            tap{4,end} = tp_svm{cc}(1,1,2,ii,ii);
            tap{5,end} = tp_svm{cc}(1,2,2,ii,ii);
        end
    end
    plot( ta, [tap{1,:}], '-.or', 'DisplayName', 'svm-O binaural', 'LineWidth', 2 );
    plot( ta, [tap{2,:}], '-.og', 'DisplayName', 'svm-b binaural' );
    plot( ta, [tap{4,:}], '-.*r', 'DisplayName', 'svm-O monaural', 'LineWidth', 2 );
    plot( ta, [tap{5,:}], '-.*g', 'DisplayName', 'svm-b monaural' );
    legend('show');
    subplot(2,2,3);
    hold all;
    title( 'glmnet & svm, avg over featureSets' );
    plot( dimValues.trainAzm,...
        mean([tp_b(1,cc,:,1,1),tp_b(1,cc,:,2,2),tp_b(1,cc,:,3,3),tp_b(1,cc,:,4,4)],3),...
        '--om', 'DisplayName', 'glmnet-b', 'LineWidth', 2 );
    plot( dimValues.trainAzm,...
        mean([tp_hws(1,cc,:,1,1),tp_hws(1,cc,:,2,2),tp_hws(1,cc,:,3,3),tp_hws(1,cc,:,4,4)],3),...
        ':*c', 'DisplayName', 'glmnet-hws' );
    ta = [];
    tap = {};
    for ii = 1 : 4
        if size( tp_svm{cc}, 4 ) >= ii  &&  size( tp_svm{cc}, 5 ) >= ii 
            ta(end+1) = dimValues.trainAzm(ii);
            tap{1,end+1}(1) = tp_svm{cc}(1,1,1,ii,ii);
            tap{2,end}(1) = tp_svm{cc}(1,2,1,ii,ii);
            tap{3,end}(1) = tp_svm{cc}(1,3,1,ii,ii);
            tap{1,end}(2) = tp_svm{cc}(1,1,2,ii,ii);
            tap{2,end}(2) = tp_svm{cc}(1,2,2,ii,ii);
            tap{3,end}(2) = tp_svm{cc}(1,3,2,ii,ii);
        end
    end
    plot( ta, cellSqueezeFun(@(cc)(mean([cc{:}])),tap(1,:),1), '-.or', 'DisplayName', 'svm-O', 'LineWidth', 2 );
    plot( ta, cellSqueezeFun(@(cc)(mean([cc{:}])),tap(2,:),1), '-.og', 'DisplayName', 'svm-b' );
    plot( ta, cellSqueezeFun(@(cc)(mean([cc{:}])),tap(3,:),1), '-.ob', 'DisplayName', 'svm-hws' );
    legend('show');
    subplot(2,2,4);
    hold all;
    title( 'svm models' );
    ta = [];
    tap = {};
    for ii = 1 : 4
        if size( tp_svm{cc}, 4 ) >= ii  &&  size( tp_svm{cc}, 5 ) >= ii 
            ta(end+1) = dimValues.trainAzm(ii);
            tap{1,end+1} = tp_svm{cc}(1,1,1,ii,ii);
            tap{2,end} = tp_svm{cc}(1,2,1,ii,ii);
            tap{3,end} = tp_svm{cc}(1,3,1,ii,ii);
            tap{4,end} = tp_svm{cc}(1,1,2,ii,ii);
            tap{5,end} = tp_svm{cc}(1,2,2,ii,ii);
            tap{6,end} = tp_svm{cc}(1,3,2,ii,ii);
        end
    end
    plot( ta, [tap{1,:}], '-.or', 'DisplayName', 'svm-O binaural', 'LineWidth', 2 );
    plot( ta, [tap{2,:}], '-.og', 'DisplayName', 'svm-b binaural' );
    plot( ta, [tap{3,:}], '-.ob', 'DisplayName', 'svm-hws binaural' );
    plot( ta, [tap{4,:}], '-.*r', 'DisplayName', 'svm-O monaural', 'LineWidth', 2 );
    plot( ta, [tap{5,:}], '-.*g', 'DisplayName', 'svm-b monaural' );
    plot( ta, [tap{6,:}], '-.*b', 'DisplayName', 'svm-hws monaural' );
    legend('show');
end


p_b_fc1 = [];
p_b_fc2 = [];
for ii = 1:4
for jj = 1:4
    p_b_fc1(ii,jj) = mean( tp_b(1,:,1,ii,jj) );
    p_b_fc2(ii,jj) = mean( tp_b(1,:,2,ii,jj) );
end
end

figure( 'Name', 'All classes mean test performance, b model' );
axes1 = axes('Parent',gcf,'YTickLabel',{'0','45','90','180'},'YTick',[1 2 3 4],...
    'XTickLabel',{'0','45','90','180'}, 'XTick',[1 2 3 4] );
xlim(axes1,[0.5 4.5]);
ylim(axes1,[0.5 4.5]);
set( gca, 'CLim', [max(0,min(min(p_b_fc1))-0.1), min(1,max(max(p_b_fc1))+0.1)] );
box(axes1,'on');
hold(axes1,'all');
image(p_b_fc1,'Parent',axes1,'CDataMapping','scaled');
xlabel('test azimuth');
ylabel('train azimuth');
title( 'binaural feature set' );
colorbar;

figure( 'Name', 'All classes mean test performance, b model' );
axes1 = axes('Parent',gcf,'YTickLabel',{'0','45','90','180'},'YTick',[1 2 3 4],...
    'XTickLabel',{'0','45','90','180'}, 'XTick',[1 2 3 4] );
xlim(axes1,[0.5 4.5]);
ylim(axes1,[0.5 4.5]);
set( gca, 'CLim', [max(0,min(min(p_b_fc2))-0.1), min(1,max(max(p_b_fc2))+0.1)] );
box(axes1,'on');
hold(axes1,'all');
image(p_b_fc2,'Parent',axes1,'CDataMapping','scaled');
xlabel('test azimuth');
ylabel('train azimuth');
title( 'monaural feature set' );
colorbar;
