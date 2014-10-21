function blockLabels = labelBlocks( soundFileName, blockFeatures, setup )
%labelBlocks ...
%
% TODO: add description
%
% blockFeatures    - Features coming from the Two!Ears Auditory Front-End module

%read annotations
onsetOffset = readOnOffAnnotations( soundFileName );

for bi = 1:size( blockFeatures, 2 )
    
    blockOnset = blockFeatures(1,bi).startTime;
    blockOffset = blockFeatures(1,bi).endTime;
    
    blockLabels(bi,1) = 0;
    for k = 1 : size( onsetOffset, 1 )
        eventOnset = onsetOffset(k,1);
        eventOffset = onsetOffset(k,2);
        eventLength = eventOffset - eventOnset;
        maxBlockEventLen = min( setup.blockCreation.blockSize, eventLength );
        eventBlockOverlapLen = min( blockOffset, eventOffset ) - max( blockOnset, eventOnset );
        relEventBlockOverlap = eventBlockOverlapLen / maxBlockEventLen;
        blockIsSoundEvent = relEventBlockOverlap > setup.Labeling.minBlockToEventRatio;
        blockLabels(bi,1) = blockLabels(bi,1) || blockIsSoundEvent;
        if blockLabels(bi,1) == 1, break, end;
    end
    
end

if annotFid ~= -1
    fclose( annotFid );
end

%scaling l to [-1..1]
blockLabels = (blockLabels * 2) - 1;
