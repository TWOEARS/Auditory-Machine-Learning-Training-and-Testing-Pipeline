idModels(1).name = 'alarm';
idModels(1).dir = '../../../../twoears-data/learned_models/IdentityKS/IEEE_special_issue_models/';
idModels(2).name = 'baby';
idModels(2).dir = idModels(1).dir;
idModels(3).name = 'fire';
idModels(3).dir = idModels(1).dir;
idModels(4).name = 'femaleSpeech';
idModels(4).dir = idModels(1).dir;

data_dir = '../../../../twoears-data';
flist = ...
    {fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/alarm.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_piano.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/dog.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire_moving.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/fire.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire_piano.mat')}; % piano_baby -> baby_dog_fire_piano
% onset of first chirp to offset of final chirp
session_onOffSet = [1.236e+05, 8582556;...   % alarm
                    8.991e+04, 15096220;...   % baby
                    88944, min([15094288, 4819608, 30081565]);...   % baby_dog_fire
                    7.4822e+04, min([15066044, 8090428]);...   % baby_piano
                    9.2152e+04, 4826024;...   % dog # previously 9.927e+04
                    5.0477e+04, min([15017354, 4742674, 3000463]);...   % baby_dog_fire_moving
                    5.4325e+04, 30012327;...   % fire
                    1.1279e+05, min([15141980, 4867300, 30129257, 8166364]);...   % piano_baby -> baby_dog_fire_piano \
                   ];
session_onOffSet = session_onOffSet / 44100.0; % from samples to seconds
for ii = 1 : numel(flist)
    fpath_mixture_mat = flist{ii};
    [idLabels{ii}, perf{ii}] = identify_rec(idModels, data_dir, fpath_mixture_mat, session_onOffSet(ii,:));
    close all
end
