%% add needed pathes

thisPath = getMFilePath();
reporoot = fileparts( fileparts( fileparts( fileparts( thisPath ) ) ) );
addpath( genpath( thisPath ) );
addpath( genpath( [getMFilePath() '..' filesep 'tools' filesep] ) );
addpath(fullfile(reporoot, 'wp1git/src'));
addpath(genpath(fullfile(reporoot, 'wp2git/src')));


%% create experiment: standard

e1setup = setupExperiment();

%% produce models for experiment

trainPath = '../../../TwoEarsRUB/train';
produceModel( trainPath, 'baby', e1setup );
produceModel( trainPath, 'dog', e1setup );

%% create experiment: standard

%e2setup = setupExperiment();
%e2setup.hyperParamSearch.kernels = [2];
%e2setup.hyperParamSearch.searchBudget = 81;

%% produce models for experiment

%produceModel( trainPath, 'dog', e2setup );
%produceModel( trainPath, 'fire', e2setup );
%produceModel( trainPath, 'knock', e2setup );
%produceModel( trainPath, 'phone', e2setup );
%produceModel( trainPath, 'piano', e2setup );

%% put together perfomance numbers of experiments for comparison

[ted, tv, tev] = makeResultsTable( trainPath, e1setup );
disp( tev );
