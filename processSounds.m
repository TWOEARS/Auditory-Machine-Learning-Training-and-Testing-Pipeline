function processSounds( dfiles, setup )

disp( 'processing of signals' );

dataHash = getAuditoryFrontEndDataHash( setup );

sim = simulator.SimulatorConvexRoom();  % simulator object
sim.loadConfig('train.xml');
sim.set('Init',true);

for k = 1:length( dfiles.signalFileNames )
    
    saveName = [dfiles.signalFileNames{k} '.' dataHash '.afe.mat'];
    if exist( saveName, 'file' )
        fprintf( '.' );
        continue;
    end;
    
    fprintf( '\n%s', saveName );

    [signal, fsHz] = audioread( dfiles.signalFileNames{k} );
    if fsHz ~= setup.dataCreation.fs
        fprintf( '\nWarning: signal is resampled from %uHz to %uHz\n', fsHz, setup.dataCreation.fs );
        signal = resample( signal, setup.dataCreation.fs, fsHz );
    end
    
    if size( signal, 1 ) > 1
        [~,m] = max( std( signal ) );
        signal = signal(:,m);
    end
    
    signal = signal ./ max( abs( signal ) );
    
    data = [];
    for angle = setup.dataCreation.angle
        
        fprintf( '.' );

        earSignals = [];
        earSignals = double( makeEarsignals( signal, angle, sim ) );
        
        fprintf( '.' );
        
        dObj = [];
        mObj = [];
        procs = [];
        dObj = dataObject( [], setup.dataCreation.fs, 2, 1 );
        mObj = manager( dObj );
        for z = 1:length( setup.dataCreation.requests )
            procs{z} = mObj.addProcessor( setup.dataCreation.requests{z}, setup.dataCreation.requestP{z} );
        end
        tmpData = cell( size(procs,2), size(procs{1},2) );
        for pos = 1:setup.dataCreation.fs:length(earSignals)
            posEnd = min( length( earSignals ), pos + setup.dataCreation.fs - 1 );
            mObj.processChunk( earSignals(pos:posEnd,:), 0 );
            for z = 1:size(procs,2)
                for zz = 1:size(procs{z},2)
                    tmpData{z,zz} = [tmpData{z,zz}; procs{z}{zz}.Data];
                end
            end
            fprintf( '.' );
        end
        for z = 1:size(procs,2)
            for zz = 1:size(procs{z},2)
                procs{z}{zz}.Data = tmpData{z,zz};
            end
        end
        data = [data procs(:)];
    end
    
    save( saveName, 'data', 'setup' );

end

sim.set('ShutDown',true);

disp( ';' );
