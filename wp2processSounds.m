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
    if fsHz ~= esetup.wp2dataCreation.fsHz
        fprintf( '\nWarning: sound is resampled from %uHz to %uHz\n', fsHz, esetup.wp2dataCreation.fsHz );
        sound = resample( sound, esetup.wp2dataCreation.fsHz, fsHz );
    end
    
    if size( sound, 1 ) > 1
        [~,m] = max( std( sound ) );
        sound = sound(:,m);
    end
    
    sound = sound ./ max( abs( sound ) );
    
    wp2data = [];
    for angle = esetup.wp2dataCreation.angle
        
        fprintf( '.' );

        earSignals = makeEarsignals( sound, angle, wp1sim );
        
        fprintf( '.' );
        
        [~,wp2cues,wp2features,~] = process_WP2( earSignals, esetup.wp2dataCreation.fsHz, wp2state );
        wp2data = [wp2data [wp2cues;wp2features]];
        
    end
    
    save( wp2SaveName, 'wp2data', 'esetup' );

end

wp1sim.set('ShutDown',true);

disp( ';' );
