function blockLabels = labelBlocks( soundFileName, wp2BlockFeatures, esetup )

%read annotations
onsetOffset = readOnOffAnnotations( soundFileName );

for bi = 1:size( wp2BlockFeatures, 2 )
    
    blockOnset = wp2BlockFeatures(1,bi).startTime;
    blockOffset = wp2BlockFeatures(1,bi).endTime;
    
    blockLabels(bi,1) = 0;
    for k = 1 : size( onsetOffset, 1 )
        eventOnset = onsetOffset(k,1);
        eventOffset = onsetOffset(k,2);
        eventLength = eventOffset - eventOnset;
        maxBlockEventLen = min( esetup.blockCreation.blockSize, eventLength );
        eventBlockOverlapLen = min( blockOffset, eventOffset ) - max( blockOnset, eventOnset );
        relEventBlockOverlap = eventBlockOverlapLen / maxBlockEventLen;
        blockIsSoundEvent = relEventBlockOverlap > esetup.Labeling.minBlockToEventRatio;
        blockLabels(bi,1) = blockLabels(bi,1) || blockIsSoundEvent;
        if blockLabels(bi,1) == 1, break, end;
    end
    
end

if annotFid ~= -1
    fclose( annotFid );
end

%scaling l to [-1..1]
blockLabels = (blockLabels * 2) - 1;