function [idLabels, perf] = identify_rec(idModels, fpath_mixture_mat, fpath_mixture_wav, session_onOffSet, ppRemoveDc,fs)
%IDENTIFY identifies sources detected in a recording and returns predicted
% source labels as well as corresponding ground truth (correct source
% label)

%warning('off', 'all');
disp( 'Initializing Two!Ears, setting up interface to mixture recorded from the robot...' );
startTwoEars('Config.xml');
startAMLTTP;

% === load ground truth
[mixture_onOffSets, target_names] = readMixtureOnOffSets(fpath_mixture_wav);
labels = cell(size(mixture_onOffSets));
numSrcs = numel(target_names);
for ii = 1 : numel(target_names)
    if strcmp(target_names(ii), 'moving')
        numSrcs = numSrcs-1;
    else
        labels{ii} = cell(1, size(mixture_onOffSets{ii}, 1));
        labels{ii}(:) = {target_names(ii)};
    end
end
labels_cat = cat(2, labels{:});
labels_cat = [labels_cat{:}];
mixture_onOffSets_cat = cat(1, mixture_onOffSets{:});

% === Initialize Interface to Jido Recording
jido = JidoRecInterface(fpath_mixture_mat, 2205*4); % blocksize = 0.05s * 4 
if numel(session_onOffSet) > 0
    jido.seekTime(session_onOffSet(1));
    mixture_onOffSets_cat = mixture_onOffSets_cat - jido.curTime_s;
    for ii = 1:numel(mixture_onOffSets)
        mixture_onOffSets{ii} = mixture_onOffSets{ii} - jido.curTime_s;
    end
end
if numel(session_onOffSet) > 1 && ~isinf(session_onOffSet(2))
    jido.setEndTime(session_onOffSet(2));
end

% === Initialise and run model(s)
disp( 'Building blackboard system...' );
bbs = buildIdentificationBBS(jido, idModels, ppRemoveDc,fs, labels_cat, mixture_onOffSets_cat);
disp( 'Starting blackboard system.' );
bbs.run();

% === Evaluate scores
%[idLabels, idMismatch] = 
[idLabels, perf] = idScoresBAC(bbs, labels, mixture_onOffSets);

% finish

% vim: set sw=4 ts=4 expandtab textwidth=90 :
