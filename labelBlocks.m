function blockLabels = labelBlocks( soundFileName, wp2BlockFeatures, esetup )

%read annotations
annotFid = fopen( [soundFileName '.txt'] );
if annotFid ~= -1
    annotLine = fgetl( annotFid );
    onsetOffset = sscanf( annotLine, '%f' );
else
    onsetOffset = [ inf, inf ];
end
eventOnset = onsetOffset(1);
eventOffset = onsetOffset(2);
eventLength = eventOffset - eventOnset;
maxBlockEventLength = min( esetup.blockCreation.blockSize, eventLength );

for blockIdx = 1:size( wp2BlockFeatures, 1 )

    blockOnset = wp2BlockFeatures(blockIdx, 1).startTime;
    blockOffset = wp2BlockFeatures(blockIdx, 1).endTime;
    soundInBlockLength = min( blockOffset, eventOffset ) - max( blockOnset, eventOnset );
    ratioBlockToSoundEvent = soundInBlockLength / maxBlockEventLength;
    blockIsSoundEvent = ratioBlockToSoundEvent > esetup.Labeling.minBlockToEventRatio;
    
    blockLabels(blockIdx,1) = blockIsSoundEvent;

end

if annotFid ~= -1
    fclose( annotFid );
end

%scaling l to [-1..1]
blockLabels = (blockLabels * 2) - 1;