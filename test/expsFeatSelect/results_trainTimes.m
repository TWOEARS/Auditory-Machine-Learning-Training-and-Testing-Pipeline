function results_trainTimes

trTimes = cell(5,2,4);  % {lasso-fs1,lasso-fs3,svm-o,svm-fs1,svm-fs3},
                        % {Binaural,Monaural}, {alarm,baby,female,fire}
teTimes = cell(5,2,4);  % {lasso-fs1,lasso-fs3,svm-o,svm-fs1,svm-fs3},
                        % {Binaural,Monaural}, {alarm,baby,female,fire}

%% azms glmnet train
load('glmnet_azms_times.mat', 'trainTime', 'testTime' );
for ff = 1:2, for cc = 1:4
    trTimes{1,ff,cc} = [trTimes{1,ff,cc} [trainTime{:,cc,ff,:}]/3600];
    trTimes{2,ff,cc} = [trTimes{2,ff,cc} [trainTime{:,cc,ff,:}]/3600];
    teTimes{1,ff,cc} = [teTimes{1,ff,cc} [testTime{1,cc,ff,:}]];
    teTimes{2,ff,cc} = [teTimes{2,ff,cc} [testTime{2,cc,ff,:}]];
end;end

%% azms svm train
load('svm_azms_times.mat', 'trainTime', 'testTime');
for ff = 1:2, for cc = 1:4, for ll = 1:3
    trTimes{2+ll,ff,cc} = [trTimes{2+ll,ff,cc} [trainTime{:,cc,ll,ff,:}]/3600];
    teTimes{2+ll,ff,cc} = [teTimes{2+ll,ff,cc} [testTime{:,cc,ll,ff,:}]];
end;end;end

%% gos glmnet train
load('glmnet_gos_times.mat', 'trainTime', 'testTime');
for ff = 1:2, for cc = 1:4
    trTimes{1,ff,cc} = [trTimes{1,ff,cc} [trainTime{cc,ff,:,:}]/3600];
    trTimes{2,ff,cc} = [trTimes{2,ff,cc} [trainTime{cc,ff,:,:}]/3600];
    teTimes{1,ff,cc} = [teTimes{1,ff,cc} [testTime{1,cc,ff,:,:}]];
    teTimes{2,ff,cc} = [teTimes{2,ff,cc} [testTime{2,cc,ff,:,:}]];
end;end

%% gos svm train
load('svm_gos_times.mat', 'trainTime', 'testTime');
for ff = 1:2, for cc = 1:4, for ll = 1:3
    trTimes{2+ll,ff,cc} = [trTimes{2+ll,ff,cc} [trainTime{cc,ll,ff,:,:}]/3600];
%    teTimes{2+ll,ff,cc} = [teTimes{2+ll,ff,cc} [testTime{cc,ll,ff,:,:}]];
end;end;end


%%
%%

% figure;
% boxplot_grps( {'alarm', 'baby', 'female', 'fire'}, ...
%               [trTimes{:,:,1}], [trTimes{:,:,2}], [trTimes{:,:,3}], [trTimes{:,:,4}] );
% 
% figure;
% boxplot_grps( {'Monaural', 'Binaural'}, ...
%               [trTimes{:,2,:}], [trTimes{:,1,:}] );

figure( 'defaulttextfontsize', 14 );
boxplot_grps( {'lasso', 'svm-O', 'svm-fs1', 'svm-fs3'}, ...
              [trTimes{1,:,:}], [trTimes{3,:,:}], [trTimes{4,:,:}], [trTimes{5,:,:}] );
ylabel( 'training time / h' );
set( gca, 'YTick', [0,1,5,10,20], 'YGrid', 'on' );

%%

trTimes = cell2mat( trTimes );
trTimes = reshape( trTimes, 5, [] );
median( trTimes, 2 )
mean( trTimes, 2 )
std( trTimes, [], 2 )

%%

figure;
boxplot_grps( {'alarm', 'baby', 'female', 'fire'}, ...
              [teTimes{:,:,1}], [teTimes{:,:,2}], [teTimes{:,:,3}], [teTimes{:,:,4}] );

figure;
boxplot_grps( {'Monaural', 'Binaural'}, ...
              [teTimes{:,2,:}], [teTimes{:,1,:}] );

figure( 'defaulttextfontsize', 14 );
boxplot_grps( {'lasso', 'svm-O', 'svm-fs1', 'svm-fs3'}, ...
              [teTimes{1,:,:}], [teTimes{3,:,:}], [teTimes{4,:,:}], [teTimes{5,:,:}] );
ylabel( 'testing time / s' );
set( gca, 'YScale', 'log' );

