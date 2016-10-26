%% mc1_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(5).name = 'fire';
% idModels(4).name = 'femaleSpeech';
% idModels(3).name = 'dog';
% idModels(6).name = 'piano';
% [idModels(1:6).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc1_models_dataset_1' );

%% mc1b_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(5).name = 'fire';
% idModels(4).name = 'femaleSpeech';
% idModels(3).name = 'dog';
% [idModels(1:5).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc1b_models_dataset_1' );

%% mc2_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(4).name = 'fire';
% idModels(3).name = 'femaleSpeech';
% [idModels(1:4).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc2_models_dataset_1' );

%% mc2b_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(4).name = 'fire';
% idModels(3).name = 'femaleSpeech';
% [idModels(1:4).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc2b_models_dataset_1' );

%% mc2segmented_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(4).name = 'fire';
% idModels(3).name = 'femaleSpeech';
% [idModels(1:4).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc2segmented_models_dataset_1' );

%% mc3_fc3_models_dataset_1
idModels(1).name = 'alarm';
idModels(2).name = 'baby';
idModels(3).name = 'crash';
idModels(4).name = 'dog';
idModels(5).name = 'engine';
idModels(6).name = 'femaleScreammaleScream';
idModels(7).name = 'femaleSpeech';
idModels(8).name = 'fire';
idModels(9).name = 'footsteps';
idModels(10).name = 'knock';
idModels(11).name = 'maleSpeech';
idModels(12).name = 'phone';
idModels(13).name = 'piano';
[idModels(1:13).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc3_fc3_models_dataset_1' );

%% mc3_fc4_0.5s_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(3).name = 'crash';
% idModels(4).name = 'dog';
% idModels(5).name = 'engine';
% idModels(6).name = 'femaleScreammaleScream';
% idModels(7).name = 'femaleSpeech';
% idModels(8).name = 'fire';
% idModels(9).name = 'footsteps';
% idModels(10).name = 'knock';
% idModels(11).name = 'maleSpeech';
% idModels(12).name = 'phone';
% idModels(13).name = 'piano';
% [idModels(1:13).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc3_fc4_0.5s_models_dataset_1' );

%% mc3_fc4_1s_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(3).name = 'crash';
% idModels(4).name = 'dog';
% idModels(5).name = 'engine';
% idModels(6).name = 'femaleScreammaleScream';
% idModels(7).name = 'femaleSpeech';
% idModels(8).name = 'fire';
% idModels(9).name = 'footsteps';
% idModels(10).name = 'knock';
% idModels(11).name = 'maleSpeech';
% idModels(12).name = 'phone';
% idModels(13).name = 'piano';
% [idModels(1:13).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc3_fc4_1s_models_dataset_1' );
%%
ppRemoveDc = false;
fs = 16000;

data_dir = '../../../../twoears-database-internal';
flist = ...
    {fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/alarm.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_piano.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/dog.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire_moving.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/fire.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire_piano.mat'),...% piano_baby -> baby_dog_fire_piano
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/alarm.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/alarm_general_footsteps_fire.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/baby.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/baby_maleSpeech_femaleSpeech_femaleScream-maleScream.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/femaleScream-maleScream.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/femaleScream-maleScream_baby.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/femaleSpeech_baby.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/fire.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/fire_alarm_baby_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/footsteps.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/general1of2.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/general2of2.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/general_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/general_maleSpeech_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/maleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160928_A/mat/maleSpeech_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/alarm_general.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/baby_femaleSpeech_general.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/baby_fire.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/baby_fire_alarm_femaleScream-maleScream.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/fire_alarm_femaleScream-maleScream.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929/mat/general_maleSpeech_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/alarm.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/baby.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/baby_fire_alarm_femaleScream-maleScream.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/baby_maleSpeech_femaleSpeech_femaleScream-maleScream.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/femaleScream-maleScream_baby.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/fire_alarm_baby_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/footsteps.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_B/mat/general_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_C/mat/baby_maleSpeech_femaleSpeech_femaleScream-maleScream.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_C/mat/femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_C/mat/fire_alarm_baby_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_D/mat/femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_D/mat/fire_alarm_baby_femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/alarm_general_footsteps_fire.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/baby_fire_alarm_femaleScream-maleScream.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/femaleScream-maleScream_baby.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/femaleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/maleSpeech.mat'), ...
    fullfile(data_dir, 'sound_databases/adream_1609/rec/bagfiles_20160929_E/mat/maleSpeech_femaleSpeech.mat'), ...
    };
% onset of first chirp (inclusive) to offset of final chirp
% (inclusive) in samples
session_onOffSet = [1.236e+05, 8582556;...   % alarm
                    8.991e+04, 15096220;...   % baby
                    88944, min([15094288, 4819608, 30081565]);...   % baby_dog_fire
                    7.4822e+04, min([15066044, 8090428]);...   % baby_piano
                    9.2152e+04, 4826024;...   % dog # previously 9.927e+04
                    5.0477e+04, min([15017354, 4742674, 3000463]);...   % baby_dog_fire_moving
                    5.4325e+04, 30012327;...   % fire
                    1.1279e+05, min([15141980, 4867300, 30129257, 8166364]);...   % piano_baby -> baby_dog_fire_piano \
                    % bagfiles_20160928_A
                    71663, inf; ... % alarm
                    120393, inf; ... % alarm_general_footsteps_fire
                    148617, inf; ... % baby
                    134505, inf; ... % baby_maleSpeech_femaleSpeech_femaleScream-maleScream
                    134946, inf; ... % femaleScream-maleScream
                    84893, inf; ... % femaleScream-maleScream_baby
                    54243, inf; ... % femaleSpeech
                    93713, inf; ... % femaleSpeech_baby
                    203433, inf;  ...% fire
                    280035, inf;  ...% fire_alarm_baby_femaleSpeech
                    189365, inf;  ...% footsteps
                    0, inf;  ...% general1of2
                    0, inf;  ...% general2of2
                    54199, inf;  ...% general_femaleSpeech
                    38808, inf;  ...% general_maleSpeech_femaleSpeech
                    75773, inf;  ...% maleSpeech
                    143325, inf;  ...% maleSpeech_femaleSpeech
                    % bagfiles_20160929':
                    64386,   inf; ...% alarm_general
                    75720, inf; ...% baby_femaleSpeech_general
                    138386, inf; ...% baby_fire
                    121716, inf; ...% baby_fire_alarm_femaleScream-maleScream
                    186984, inf; ...% fire_alarm_femaleScream-maleScream
                    45026 inf; ...% general_maleSpeech_femaleSpeech
                    % bagfiles_20160929_B:
                    63284,   inf; ...% alarm
                    70560,   inf; ...% baby
                    132388,   inf; ...% baby_fire_alarm_femaleScream-maleScream
                    93713,   inf; ...% baby_maleSpeech_femaleSpeech_femaleScream-maleScream
                    64739,   inf; ...% femaleScream-maleScream_baby
                    88641,   inf; ...% fire_alarm_baby_femaleSpeech
                    33957,   inf; ...% footsteps
                    51994,   inf; ...% general_femaleSpeech
                    % bagfiles_20160929_C
                    72324, inf; ...% baby_maleSpeech_femaleSpeech_femaleScream-maleScream
                    60858, inf; ...% femaleSpeech
                    62446, inf; ...% fire_alarm_baby_femaleSpeech
                    % bagfiles_20160929_D
                    92831, inf; ...% femaleSpeech
                    76293, inf; ...% fire_alarm_baby_femaleSpeech
                    % bagfiles_20160929_E
                    430416, inf; ...% alarm_general_footsteps_fire
                    380583, inf; ...% baby_fire_alarm_femaleScream-maleScream
                    323694, inf; ...% femaleScream-maleScream_baby
                    304378, inf; ...% femaleSpeech
                    323694, inf; ...% maleSpeech
                    323694, inf; ...% maleSpeech_femaleSpeech
                   ];
session_onOffSet = session_onOffSet / 44100.0; % from samples to seconds
for ii = 1 : numel(flist)
    fpath_mixture_mat = flist{ii};
    [subdir, fname, ext] = fileparts(fpath_mixture_mat);
    sessiondir = fileparts(subdir); % e.g bagfiles_20160929_B
    if strcmp(ext, '.mat')
        fpath_mixture_wav = fullfile(sessiondir, 'wav', [fname, '.wav']);
    elseif strcmp(ext, '.wav')
        % do nothing
    else
        error('Unrecognized mixture file %s', fpath_mixture_mat);
    end
    [idLabels{ii}, perf{ii}] = identify_rec(idModels, ...
        fpath_mixture_mat, fpath_mixture_wav, ...
        session_onOffSet(ii,:), ...
        ppRemoveDc, fs);
    close all
end

p = arrayfun( @(x)(x.performance), vertcat( perf{:} ) );
disp( p );

perfOverview = vertcat( perf{:} );
tp1 = sum( arrayfun( @(x)(x.tp), perfOverview([1,2,5,7],:) ) );
fp1 = sum( arrayfun( @(x)(x.fp), perfOverview([1,2,5,7],:) ) );
tn1 = sum( arrayfun( @(x)(x.tn), perfOverview([1,2,5,7],:) ) );
fn1 = sum( arrayfun( @(x)(x.fn), perfOverview([1,2,5,7],:) ) );

tpfn1 = tp1 + fn1;
tnfp1 = tn1 + fp1;

sens1 = tp1 ./ tpfn1;
spec1 = tn1 ./ tnfp1;
bac1 = 0.5*sens1 + 0.5*spec1;

tp2 = sum( arrayfun( @(x)(x.tp), perfOverview([3,4,6,8],:) ) );
fp2 = sum( arrayfun( @(x)(x.fp), perfOverview([3,4,6,8],:) ) );
tn2 = sum( arrayfun( @(x)(x.tn), perfOverview([3,4,6,8],:) ) );
fn2 = sum( arrayfun( @(x)(x.fn), perfOverview([3,4,6,8],:) ) );

tpfn2 = tp2 + fn2;
tnfp2 = tn2 + fp2;

sens2 = tp2 ./ tpfn2;
spec2 = tn2 ./ tnfp2;
bac2 = 0.5*sens2 + 0.5*spec2;
