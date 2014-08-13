function blockifyData( soundsDir, className, esetup )

disp( 'blockifying data' );

[~, soundFileNames] = makeSoundLists( soundsDir, className );

blockDataHash = getBlockDataHash( esetup );
for i = 1:length( soundFileNames )
    
    fprintf( '.' );
    
    blocksSaveName = [soundFileNames{i} '.' blockDataHash '.blocks.mat'];
    if exist( blocksSaveName, 'file' ); continue; end;

    wp2SaveName = [soundFileNames{i} '.' getWp2dataHash( esetup ) '.wp2.mat'];
    ls = load( wp2SaveName, 'wp2data' );
    wp2data = ls.wp2data;
    
    wp2BlockFeatures = [];
    
    for k = 1:size( wp2data, 1 ) % different wp2cues/features
        wp2BlockFeaturesTmp = [];
        for j = 1:size( wp2data, 2 ) % different earsignals (e.g. different angles)
            
            fprintf( '.' );
            
            nHops = size( wp2data(k,j).data, 2 );
            bs = getBlockSizes( esetup );
            nHopsMinusLastBlock = max( nHops - bs.hopsPerBlock, 0 );
            for blockIdx = 1:(1 + ceil( nHopsMinusLastBlock / bs.hopsPerShift ) )
                
                blockstart = 1 + (blockIdx - 1) * bs.hopsPerShift;
                blockend = min( blockstart + bs.hopsPerBlock - 1, nHops );
                if (blockend - blockstart + 1) < bs.hopsPerBlock
                    blockstart = nHopsMinusLastBlock + 1;
                end
                block = wp2data(k,j);
                block.data = block.data(:,blockstart:blockend,:);
                block.startTime = (blockstart - 1) * esetup.wp2dataCreation.hopSizeSec;
                block.endTime = (blockend - 1) * esetup.wp2dataCreation.hopSizeSec + esetup.wp2dataCreation.winSizeSec;
                
                wp2BlockFeaturesTmp = [wp2BlockFeaturesTmp;block];
            end
        end
        wp2BlockFeatures = [wp2BlockFeatures wp2BlockFeaturesTmp];
    end
    
    fprintf( '.' );
    save( blocksSaveName, 'wp2BlockFeatures', 'esetup' );
    
end

disp( ';' );
