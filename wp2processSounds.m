function wp2processSounds( soundsDir, className, esetup )

disp( 'wp2 processing of sounds' );

[classSoundFileNames, soundFileNames] = makeSoundLists( soundsDir, className );

wp2DataHash = getWp2dataHash( esetup );

startWP1;
import simulator.*
import xml.*
wp1sim = SimulatorConvexRoom();  % simulator object
wp1sim.loadConfig('train.xml');
wp1sim.set('Init',true);

for k = 1:length( soundFileNames )
    
    wp2SaveName = [soundFileNames{k} '.' wp2DataHash '.wp2.mat'];
    if exist( wp2SaveName, 'file' )
        fprintf( '.' );
        continue;
    end;
    
    fprintf( '\n%s', wp2SaveName );

    [sound, fsHz] = audioread( soundFileNames{k} );
    if fsHz ~= esetup.wp2dataCreation.fs
        fprintf( '\nWarning: sound is resampled from %uHz to %uHz\n', fsHz, esetup.wp2dataCreation.fs );
        sound = resample( sound, esetup.wp2dataCreation.fs, fsHz );
    end
    
    if size( sound, 1 ) > 1
        [~,m] = max( std( sound ) );
        sound = sound(:,m);
    end
    
    sound = sound ./ max( abs( sound ) );
    
    wp2data = [];
    for angle = esetup.wp2dataCreation.angle
        
        fprintf( '.' );

        earSignals = [];
        earSignals = double( makeEarsignals( sound, angle, wp1sim ) );
        
        fprintf( '.' );
        
        dObj = [];
        mObj = [];
        wp2procs = [];
        dObj = dataObject( earSignals, esetup.wp2dataCreation.fs );
        mObj = manager( dObj );
        for z = 1:length( esetup.wp2dataCreation.requests )
            wp2procs{z} = mObj.addProcessor( esetup.wp2dataCreation.requests{z}, esetup.wp2dataCreation.requestP{z} );
        end
        mObj.processSignal();
        wp2data = [wp2data [wp2procs{:}]'];
    end
    
    save( wp2SaveName, 'wp2data', 'esetup' );

end

wp1sim.set('ShutDown',true);

disp( ';' );
