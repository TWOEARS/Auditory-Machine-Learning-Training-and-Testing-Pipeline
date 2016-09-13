function [idLabels, perfs] = idScoresBAC(bbs, labels, onOffsets)

fprintf( '\n\nEvaluate scores...\n\n' );
idHyps = bbs.blackboard.getData( 'identityHypotheses' );
idMismatch = getIdDecisions( idHyps );
idLabels = sort( fieldnames( idMismatch ) );

% assume blockSize remains constant throughout
% assume all hypotheses have the same concernsBlocksize_s
assert( numel(labels) == numel(onOffsets) );
labelBlockSize_s = idHyps(1).data(1).concernsBlocksize_s;
%blockAnnotations_list = {};
types = cell(1, numel( labels ) );
for il = 1 : numel( labels )
    if ~isempty(labels{il})
        types(il) = labels{il}(1);
        for idl = 1 : numel( idLabels )
            if strcmp(idLabels{idl}, types{il})
                idMismatch.(idLabels{idl}).labelIdx = il;
            end
        end % idLabels
    end
end % labels

labeler = StandaloneMultiEventTypeLabeler( ...
            'labelBlockSize_s', labelBlockSize_s, ...
            'types', types );

% populate the ground truth
groundTruth = zeros(numel( idHyps ), numel( labels ));
% for each hypothesis, create a block annotation struct to use with the
% labelcreator instance
for ih = 1:numel(idHyps)
    blockAnnotations.blockOffset =  idHyps(ih).sndTmIdx;
    blockAnnotations.blockOnset = max( 0, ...
        blockAnnotations.blockOffset - idHyps(ih).data(1).concernsBlocksize_s );
    blockAnnotations.srcType.t.onset = [];
    blockAnnotations.srcType.t.offset = [];
    blockAnnotations.srcType.srcType = {};
    for il = 1 : numel( labels )
        ons = onOffsets{il}(:,1);
        offs = onOffsets{il}(:,2);
        rows = find(blockAnnotations.blockOnset >= ons & ...
            blockAnnotations.blockOffset < offs, 1);
        blockAnnotations.srcType.t.onset = [blockAnnotations.srcType.t.onset, ons(rows)];
        blockAnnotations.srcType.t.offset = [blockAnnotations.srcType.t.offset, offs(rows)];
        for r = 1 : numel( rows )
            blockAnnotations.srcType.srcType = [blockAnnotations.srcType.srcType; ...
                labels{il}(r), NaN];
        end
        %blockAnnotations_list = [blockAnnotations_list; blockAnnotations];
        if ~isempty( blockAnnotations.srcType.srcType )
            groundTruth(ih,:) = labeler.labelBlock( blockAnnotations );
        end
    end % labels, onOffsets
end % idHyps

groundTruth(groundTruth == 0) = -1; % from [0, 1] to [-1, 1]

perfs = zeros(1, numel( idLabels ));
for idl = 1 : numel( idLabels )
    if isfield( idMismatch.(idLabels{idl}) , 'labelIdx' )
        yTrue = groundTruth(:, idMismatch.(idLabels{idl}).labelIdx);
    else
        yTrue = zeros(numel(idHyps), 1) - 1;
    end
    yPred = idMismatch.(idLabels{idl}).y(1:end-1)';
    % remove uncertain blocks
    yTrue = yTrue(~isnan(yTrue));
    yPred = yPred(~isnan(yTrue));
    perfmeasure = PerformanceMeasures.BAC( yTrue, yPred );
    [~, perf, ~] = perfmeasure.calcPerformance( yTrue, yPred );
    disp(idLabels{idl})
    disp(perf)
    perfs(idl) = perf;
end
