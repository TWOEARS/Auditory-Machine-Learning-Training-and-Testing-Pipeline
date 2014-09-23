function wp2processSounds( dfiles, esetup )

disp( 'wp2 processing of sounds' );

wp2DataHash = getWp2dataHash( esetup );

startWP1;
import simulator.*
import xml.*
wp1sim = SimulatorConvexRoom();  % simulator object
wp1sim.loadConfig('train.xml');
wp1sim.set('Init',true);

for k = 1:length( dfiles.soundFileNames )
    
    wp2SaveName = [dfiles.soundFileNames{k} '.' wp2DataHash '.wp2.mat'];
    if exist( wp2SaveName, 'file' )
        fprintf( '.' );
        continue;
    end;
    
    fprintf( '\n%s', wp2SaveName );

    [sound, fsHz] = audioread( dfiles.soundFileNames{k} );
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
        dObj = dataObject( [], esetup.wp2dataCreation.fs, 2, 1 );
        mObj = manager( dObj );
        for z = 1:length( esetup.wp2dataCreation.requests )
            wp2procs{z} = mObj.addProcessor( esetup.wp2dataCreation.requests{z}, esetup.wp2dataCreation.requestP{z} );
        end
        tmpData = cell( size(wp2procs,2), size(wp2procs{1},2) );
        for pos = 1:esetup.wp2dataCreation.fs:length(earSignals)
            posEnd = min( length( earSignals ), pos + esetup.wp2dataCreation.fs - 1 );
            mObj.processChunk( earSignals(pos:posEnd,:), 0 );
            for z = 1:size(wp2procs,2)
                for zz = 1:size(wp2procs{z},2)
                    tmpData{z,zz} = [tmpData{z,zz}; wp2procs{z}{zz}.Data];
                end
            end
            fprintf( '.' );
        end
        for z = 1:size(wp2procs,2)
            for zz = 1:size(wp2procs{z},2)
                wp2procs{z}{zz}.Data = tmpData{z,zz};
            end
        end
        wp2data = [wp2data wp2procs(:)];
    end
    
    save( wp2SaveName, 'wp2data', 'esetup' );

end

wp1sim.set('ShutDown',true);

disp( ';' );
