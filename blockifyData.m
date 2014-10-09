function blockifyData( dfiles, setup )

disp( 'blockifying data' );

blockDataHash = getBlockDataHash( setup );
for z = 1:length( dfiles.soundFileNames )
    
    fprintf( '.' );
    
    blocksSaveName = [dfiles.soundFileNames{z} '.' blockDataHash '.blocks.mat'];
    if exist( blocksSaveName, 'file' ); continue; end;
    
    saveName = [dfiles.soundFileNames{z} '.' getAuditoryFrontEndDataHash( setup ) '.afe.mat'];
    tmpData = load( saveName, 'data' );
    data = tmpData.data;
    
    blockFeatures = [];
    
    for k = 1:size( data, 1 ) % different Auditory Front-End requests
        blockFeaturesTmp = [];
        for m = 1:size( data, 2 ) % different earsignals (e.g. different angles)
            
            fprintf( '.' );
            
            sigLen = size( data{k,m}{1}.Data, 1 );
            [blockLen,shiftLen] = getBlockSizes( setup, data{k,m}{1} );
            sigLenMinusLastBlock = max( sigLen - blockLen, 0 );
            nBlocks = (1 + ceil( sigLenMinusLastBlock / shiftLen ) );
            for bi = 1:nBlocks
                blockstart = 1 + (bi - 1) * shiftLen;
                blockend = min( blockstart + blockLen - 1, sigLen );
                if (blockend - blockstart + 1) < blockLen
                    blockstart = sigLenMinusLastBlock + 1;
                end
                block = [];
                block.Data{1} = data{k,m}{1}.Data(blockstart:blockend,:);
                block.Data{2} = data{k,m}{2}.Data(blockstart:blockend,:);
                block.startTime = (blockstart - 1) / data{k,m}{1}.FsHz;
                block.endTime = blockend / data{k,m}{1}.FsHz; % incorrect. See below
                % endTime = (blockend - 1) / data{k,m}{1}.FsHz + setup.dataCreation.winSizeSec;
                block.Name = data{k,m}{1}.Name;
                block.Dimensions = data{k,m}{1}.Dimensions;
                block.FsHz = data{k,m}{1}.FsHz;
                block.Canal{1} = data{k,m}{1}.Canal;
                block.Canal{2} = data{k,m}{2}.Canal;
                
                blockFeaturesTmp = [blockFeaturesTmp block];
            end
        end
        blockFeatures = [blockFeatures; blockFeaturesTmp];
    end
    
    fprintf( '.' );
    save( blocksSaveName, 'blockFeatures', 'setup' );
    
end

disp( ';' );
