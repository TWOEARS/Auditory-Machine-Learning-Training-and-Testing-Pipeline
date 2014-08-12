function wp2processSounds( soundsDir, className, niState )

disp( 'wp2 processing of sounds' );

[classSoundFileNames, soundFileNames] = makeSoundLists( soundsDir, className );

%wp2state = init_WP2( niState.wp2dataCreation.strFeatures, niState.wp2dataCreation.strCues, niState.wp2dataCreation );
wp2DataHash = getWp2dataHash( niState );

startWP1;
import simulator.*
import xml.*
wp1sim = SimulatorConvexRoom();  % simulator object
wp1sim.loadConfig('train.xml');
wp1sim.set('Init',true);

for i = 1:length( soundFileNames )
    
    wp2SaveName = [soundFileNames{i} '.' wp2DataHash '.wp2.mat'];
    if exist( wp2SaveName, 'file' )
        fprintf( '.' );
        continue;
    end;
    
    fprintf( '\n%s', wp2SaveName );

    [sound, fsHz] = audioread( soundFileNames{i} );
    if fsHz ~= niState.wp2dataCreation.fsHz
        fprintf( '\nWarning: sound is resampled from %uHz to %uHz\n', fsHz, niState.wp2dataCreation.fsHz );
        sound = resample( sound, niState.wp2dataCreation.fsHz, fsHz );
    end
    
    if size( sound, 1 ) > 1
        [~,i] = max( std( sound ) );
        sound = sound(:,i);
    end
    
    sound = sound ./ max( abs( sound ) );
    
    wp2data = [];
    for angle = niState.wp2dataCreation.angle
        
        fprintf( '.' );
        
        earSignals = makeEarsignals( sound, angle, wp1sim );
        
        fprintf( '.' );
        
        [~,wp2cues,wp2features,~] = process_WP2( earSignals, niState.wp2dataCreation.fsHz, wp2state );
        wp2data = [wp2data [wp2cues;wp2features]];
        
    end
    
    save( wp2SaveName, 'wp2data', 'niState' );

end

disp( ';' );
