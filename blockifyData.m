function blockifyData( soundsDir, className, esetup )

disp( 'blockifying data' );

[~, soundFileNames] = makeSoundLists( soundsDir, className );

blockDataHash = getBlockDataHash( esetup );
for z = 1:length( soundFileNames )
    
    fprintf( '.' );
    
    blocksSaveName = [soundFileNames{z} '.' blockDataHash '.blocks.mat'];
    if exist( blocksSaveName, 'file' ); continue; end;
    
    wp2SaveName = [soundFileNames{z} '.' getWp2dataHash( esetup ) '.wp2.mat'];
    ls = load( wp2SaveName, 'wp2data' );
    wp2data = ls.wp2data;
    
    wp2BlockFeatures = [];
    
    for k = 1:size( wp2data, 1 ) % different wp2 requests
        wp2BlockFeaturesTmp = [];
        for m = 1:size( wp2data, 2 ) % different earsignals (e.g. different angles)
            
            fprintf( '.' );
            
            sigLen = size( wp2data{k,m}{1}.Data, 1 );
            [blockLen,shiftLen] = getBlockSizes( esetup, wp2data{k,m}{1} );
            sigLenMinusLastBlock = max( sigLen - blockLen, 0 );
            nBlocks = (1 + ceil( sigLenMinusLastBlock / shiftLen ) );
            for bi = 1:nBlocks
                blockstart = 1 + (bi - 1) * shiftLen;
                blockend = min( blockstart + blockLen - 1, sigLen );
                if (blockend - blockstart + 1) < blockLen
                    blockstart = sigLenMinusLastBlock + 1;
                end
                block = [];
                block.Data{1} = wp2data{k,m}{1}.Data(blockstart:blockend,:);
                block.Data{2} = wp2data{k,m}{2}.Data(blockstart:blockend,:);
                block.startTime = (blockstart - 1) / wp2data{k,m}{1}.FsHz;
                block.endTime = blockend / wp2data{k,m}{1}.FsHz; % incorrect. See below
                % endTime = (blockend - 1) / wp2data{k,m}{1}.FsHz + esetup.wp2dataCreation.winSizeSec;
                block.Name = wp2data{k,m}{1}.Name;
                block.Dimensions = wp2data{k,m}{1}.Dimensions;
                block.FsHz = wp2data{k,m}{1}.FsHz;
                block.Canal{1} = wp2data{k,m}{1}.Canal;
                block.Canal{2} = wp2data{k,m}{2}.Canal;
                
                wp2BlockFeaturesTmp = [wp2BlockFeaturesTmp block];
            end
        end
        wp2BlockFeatures = [wp2BlockFeatures; wp2BlockFeaturesTmp];
    end
    
    fprintf( '.' );
    save( blocksSaveName, 'wp2BlockFeatures', 'esetup' );
    
end

disp( ';' );
