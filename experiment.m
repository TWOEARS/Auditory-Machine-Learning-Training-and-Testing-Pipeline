%% add needed pathes

thisPath = getMFilePath();
addpath( genpath( thisPath ) );
addpath( genpath( [getMFilePath() '..' filesep 'tools' filesep] ) );
reporoot = fileparts( fileparts( fileparts( fileparts( thisPath ) ) ) );
addpath(fullfile(reporoot, 'wp1git/src'));
%addpath(genpath(fullfile(reporoot, 'wp2git/src')));
%addpath(genpath(fullfile(reporoot, 'wp3git/src')));
%addpath(genpath(fullfile(reporoot, 'twoears-ssr/mex')));

startWP1;


%% create experiment: standard

e1setup = setupExperiment();
%% produce models for experiment

trainPath = '../../dataGit/sound_databases/IEEE_AASP/train';
produceModel( trainPath, 'alert', e1setup );
produceModel( trainPath, 'clearthroat', e1setup );
produceModel( trainPath, 'cough', e1setup );
produceModel( trainPath, 'doorslam', e1setup );
produceModel( trainPath, 'drawer', e1setup );
produceModel( trainPath, 'keyboard', e1setup );
produceModel( trainPath, 'keys', e1setup );
produceModel( trainPath, 'knock', e1setup );
produceModel( trainPath, 'laughter', e1setup );
produceModel( trainPath, 'mouse', e1setup );
produceModel( trainPath, 'pageturn', e1setup );
produceModel( trainPath, 'pendrop', e1setup );
produceModel( trainPath, 'phone', e1setup );
produceModel( trainPath, 'speech', e1setup );
produceModel( trainPath, 'switch', e1setup );

%% create experiment: standard

e2setup = setupExperiment();
e2setup.hyperParamSearch.kernels = [2];
e2setup.hyperParamSearch.searchBudget = 81;

%% produce models for experiment

produceModel( trainPath, 'alert', e2setup );
produceModel( trainPath, 'clearthroat', e2setup );
produceModel( trainPath, 'cough', e2setup );
produceModel( trainPath, 'doorslam', e2setup );
produceModel( trainPath, 'drawer', e2setup );
produceModel( trainPath, 'keyboard', e2setup );
produceModel( trainPath, 'keys', e2setup );
produceModel( trainPath, 'knock', e2setup );
produceModel( trainPath, 'laughter', e2setup );
produceModel( trainPath, 'mouse', e2setup );
produceModel( trainPath, 'pageturn', e2setup );
produceModel( trainPath, 'pendrop', e2setup );
produceModel( trainPath, 'phone', e2setup );
produceModel( trainPath, 'speech', e2setup );
produceModel( trainPath, 'switch', e2setup );

%% put together perfomance numbers of experiments for comparison

[ted, tv, tev] = makeResultsTable( trainPath, e1setup, e2setup );
disp( tev );
