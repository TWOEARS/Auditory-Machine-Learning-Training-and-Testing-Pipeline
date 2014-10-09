% FIXME: this seems to be more a test script and should be moved to the test
% folder

%% add needed pathes

thisPath = getMFilePath();
reporoot = fileparts( fileparts( fileparts( fileparts( thisPath ) ) ) );
addpath( genpath( thisPath ) );
addpath( genpath( [getMFilePath() '..' filesep 'tools' filesep] ) );
addpath(fullfile(reporoot, 'wp1git/src'));
addpath(genpath(fullfile(reporoot, 'wp2git/src')));

trainPath = [ reporoot filesep 'dataGit' filesep 'sound_databases' filesep 'generalSoundsNI' ];

%% create experiment

e1setup = setupExperiment();

e2setup = setupExperiment();
e2setup.wp2dataCreation.requestP{1} = genParStruct( ...
    'nChannels',16, ...
    'rm_scaling', 'magnitude' ... 
    );
e2setup.featureCreation.function = @msFeatures;
e2setup.featureCreation.functionParam.derivations = 1;

e3setup = setupExperiment();
e3setup.wp2dataCreation.requestP{1} = genParStruct( ...
    'nChannels',32, ...
    'rm_scaling', 'magnitude' ... 
    );
e3setup.featureCreation.function = @msFeatures;
e3setup.featureCreation.functionParam.derivations = 2;

%% produce models for experiment

produceModel( trainPath, 'baby', e1setup );
produceModel( trainPath, 'femaleSpeech', e1setup );
produceModel( trainPath, 'fire', e1setup );

produceModel( trainPath, 'baby', e2setup );
produceModel( trainPath, 'femaleSpeech', e2setup );
produceModel( trainPath, 'baby', e3setup );
produceModel( trainPath, 'femaleSpeech', e3setup );

produceModel( trainPath, 'fire', e2setup );
produceModel( trainPath, 'fire', e3setup );

produceModel( trainPath, 'dog', e1setup );
produceModel( trainPath, 'dog', e2setup );
produceModel( trainPath, 'dog', e3setup );

produceModel( trainPath, 'piano', e1setup );
produceModel( trainPath, 'piano', e2setup );
produceModel( trainPath, 'piano', e3setup );

produceModel( trainPath, 'phone', e1setup );
produceModel( trainPath, 'phone', e2setup );
produceModel( trainPath, 'phone', e3setup );

produceModel( trainPath, 'knock', e1setup );
produceModel( trainPath, 'knock', e2setup );
produceModel( trainPath, 'knock', e3setup );



%%
[ted, tv, tev] = makeResultsTable( trainPath, e1setup, e2setup, e3setup );
disp( tev );

% %% create experiment: standard
% 
% e3setup = setupExperiment();
% e3setup.featureCreation.function = @msFeatures;
% e3setup.featureCreation.functionParam.derivations = 1;
% e3setup.wp2dataCreation.requestP{1} = genParStruct( ...
%     'nChannels',8, ...
%     'rm_scaling', 'magnitude' ... 
%     );
% 
% %% produce models for experiment
% 
% produceModel( trainPath, 'baby', e3setup );
% produceModel( trainPath, 'dog', e3setup );
% produceModel( trainPath, 'femaleSpeech', e3setup );
% produceModel( trainPath, 'fire', e3setup );
% 
% %% put together perfomance numbers of experiments for comparison
% 
% [ted, tv, tev] = makeResultsTable( trainPath, e1setup, e2setup, e3setup );
% disp( tev );
