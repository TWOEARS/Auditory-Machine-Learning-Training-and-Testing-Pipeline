classdef SceneConfiguration < handle

    %% -----------------------------------------------------------------------------------
    properties
        angleSignal;
        distSignal;
        numOverlays;
        angleOverlays;
        distOverlays;
        SNRs;
        typeOverlays;
        overlays;
        offsetOverlays;
        room;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SceneConfiguration() % creates a "clean" configuration
            obj.angleSignal = dataProcs.ValGen( 'manual', 0 );
            obj.distSignal = dataProcs.ValGen( 'manual', 3 );
            obj.numOverlays = 0;
            obj.room = dataProcs.ValGen( 'manual', [] );
            obj.angleOverlays = dataProcs.ValGen.empty;
            obj.distOverlays = dataProcs.ValGen.empty;
            obj.SNRs = dataProcs.ValGen.empty;
            obj.typeOverlays = cell(0);
            obj.overlays = dataProcs.ValGen.empty;
            obj.offsetOverlays= dataProcs.ValGen.empty;
        end
        %% -------------------------------------------------------------------------------

        function addOverlay( obj, angle, dist, SNR, type, file, offset_s )
            obj.numOverlays = obj.numOverlays + 1;
            if ~isa( angle, 'dataProcs.ValGen' ), error( 'Use a dataProcs.ValGen' ); end;
            obj.angleOverlays(obj.numOverlays) = angle;
            if ~isa( dist, 'dataProcs.ValGen' ), error( 'Use a dataProcs.ValGen' ); end;
            obj.distOverlays(obj.numOverlays) = dist;
            if ~isa( SNR, 'dataProcs.ValGen' ), error( 'Use a dataProcs.ValGen' ); end;
            obj.SNRs(obj.numOverlays) = SNR;
            if sum( strcmpi( type, {'point', 'diffuse'} ) ) == 0
                error( 'Unknown overlay type' );
            end
            obj.typeOverlays{obj.numOverlays} = type;
            if ~isa( file, 'dataProcs.ValGen' ), error( 'Use a dataProcs.ValGen' ); end;
            obj.overlays(obj.numOverlays) = file;
            if ~isa( offset_s, 'dataProcs.ValGen' ), error( 'Use a dataProcs.ValGen' ); end;
            obj.offsetOverlays(obj.numOverlays) = offset_s;
        end
        %% -------------------------------------------------------------------------------
        
        function addRoom( obj, room )
            if ~isa( room, 'dataProcs.RoomValGen' ), error( 'Use a dataProcs.RoomValGen' ); end;
            obj.room = room;
        end
        %% -------------------------------------------------------------------------------

        function confInst = instantiate( obj )
            confInst = dataProcs.SceneConfiguration();
            confInst.angleSignal = dataProcs.ValGen( 'manual', obj.angleSignal.value );
            confInst.distSignal = dataProcs.ValGen( 'manual', obj.distSignal.value );
            confInst.numOverlays = obj.numOverlays;
            confInst.room = dataProcs.ValGen( 'manual', obj.room.value );
            for kk = 1:obj.numOverlays
                confInst.angleOverlays(kk) = dataProcs.ValGen( 'manual', obj.angleOverlays(kk).value );
                confInst.distOverlays(kk) = dataProcs.ValGen( 'manual', obj.distOverlays(kk).value );
                confInst.SNRs(kk) = dataProcs.ValGen( 'manual', obj.SNRs(kk).value );
                confInst.typeOverlays{kk} = obj.typeOverlays{kk};
                confInst.overlays(kk) = dataProcs.ValGen( 'manual', obj.overlays(kk).value );
                confInst.offsetOverlays(kk) = dataProcs.ValGen( 'manual', obj.offsetOverlays(kk).value );
            end
        end
        %% -------------------------------------------------------------------------------

        function splittedConfs = split( obj )
            splittedConfs(1) = dataProcs.SceneConfiguration();
            splittedConfs(1).angleSignal = copy( obj.angleSignal );
            splittedConfs(1).distSignal = copy( obj.distSignal );
            splittedConfs(1).room = copy( obj.room );
            for kk = 1:obj.numOverlays
                splittedConfs(kk+1) = dataProcs.SceneConfiguration();
                splittedConfs(kk+1).numOverlays = 1;
                splittedConfs(kk+1).angleOverlays(1) = copy( obj.angleOverlays(kk) );
                splittedConfs(kk+1).distOverlays(1) = copy( obj.distOverlays(kk) );
                splittedConfs(kk+1).SNRs(1) = copy( obj.SNRs(kk) );
                splittedConfs(kk+1).typeOverlays{1} = obj.typeOverlays{kk};
                splittedConfs(kk+1).overlays(1) = copy( obj.overlays(kk) );
                splittedConfs(kk+1).offsetOverlays(1) = copy( obj.offsetOverlays(kk) );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj, cObj )
            if ~isequaln( obj.numOverlays, cObj.numOverlays )
                e = false;
                return;
            end
            for kk = 1 : obj.numOverlays
                if ~isequal( obj.overlays(kk), cObj.overlays(kk) )
                    e = false;
                    return;
                end
            end
            if isempty( obj.room.value ) && isprop( cObj, 'walls' ) ...
                    && isempty( cObj.walls.value ) % compatibility to former walls prop
                wallsRoomEq = true;
            else
                wallsRoomEq = isequaln( obj.room, cObj.room );
            end
            e = ...
                isequaln( obj.angleSignal, cObj.angleSignal) && ...
                isequaln( obj.distSignal, cObj.distSignal ) && ...
                isequaln( obj.angleOverlays, cObj.angleOverlays ) && ...
                isequaln( obj.distOverlays, cObj.distOverlays ) && ...
                isequaln( obj.SNRs, cObj.SNRs ) && ...
                isequaln( obj.typeOverlays, cObj.typeOverlays ) && ...
                isequaln( obj.offsetOverlays, cObj.offsetOverlays ) && ...
                wallsRoomEq;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end
