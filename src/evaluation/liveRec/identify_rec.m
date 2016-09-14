function [idLabels, perf] = identify_rec(idModels, data_dir, fpath_mixture_mat, session_onOffSet)
%IDENTIFY identifies sources detected in a recording and returns predicted
% source labels as well as corresponding ground truth (correct source
% label)

%warning('off', 'all');
disp( 'Initializing Two!Ears, setting up interface to mixture recorded from the robot...' );
startTwoEars('Config.xml');
startIdentificationTraining;

[~, fname, ext] = fileparts(fpath_mixture_mat);
if strcmp(ext, '.mat')
    wav_dir = fullfile(data_dir, 'sound_databases/adream_1605/rec/wav');
    fpath_mixture_wav = fullfile(wav_dir, [fname, '.wav']);
elseif strcmp(ext, '.wav')
    % do nothing
else
    error('Unrecognized mixture file %s', fpath_mixture_mat);
end
% === load ground truth
[mixture_onOffSets, target_names] = readMixtureOnOffSets(fpath_mixture_wav);
labels = cell(size(mixture_onOffSets));
for ii = 1 : numel(target_names)
    labels{ii} = cell(1, size(mixture_onOffSets{ii}, 1));
    labels{ii}(:) = {target_names(ii)};
end
labels_cat = cat(2, labels{:});
labels_cat = [labels_cat{:}];
mixture_onOffSets_cat = cat(1, mixture_onOffSets{:});

% === Initialize Interface to Jido Recording
jido = JidoRecInterface(fpath_mixture_mat);
if numel(session_onOffSet) > 0
    jido.seekTime(session_onOffSet(1));
    mixture_onOffSets_cat = mixture_onOffSets_cat - session_onOffSet(1);
    for ii = 1:numel(mixture_onOffSets)
        mixture_onOffSets{ii} = mixture_onOffSets{ii} - session_onOffSet(1);
    end
end
if numel(session_onOffSet) > 1 && ~isinf(session_onOffSet(2))
    jido.setEndTime(session_onOffSet(2));
end

% === Initialise and run model(s)
disp( 'Building blackboard system...' );
bbs = buildIdentificationBBS(jido, idModels, labels_cat, mixture_onOffSets_cat);
disp( 'Starting blackboard system.' );
bbs.run();

% === Evaluate scores
%[idLabels, idMismatch] = 
[idLabels, perf] = idScoresBAC(bbs, labels, mixture_onOffSets);

% finish

% vim: set sw=4 ts=4 expandtab textwidth=90 :
