classdef MultiCondition < handle

    properties
        angleSignal;
        numOverlays;
        angleOverlays;
        SNRs;
        typeOverlays;
        fileOverlays;
        offsetOverlays;
        walls;
    end

    methods
        
        function obj = MultiCondition() % creates a clean MC
            obj.angleSignal = 0;
            obj.numOverlays = 0;
            obj.walls = [];
        end
        
        function addOverlay( obj, angle, SNR, type, file, offset_s )
            obj.numOverlays = obj.numOverlays + 1;
            if ~isa( angle, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.angleOverlays(obj.numOverlays) = angle;
            if ~isa( SNR, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.SNRs(obj.numOverlays) = SNR;
            if sum( strcmpi( type, {'point', 'diffuse'} ) ) == 0
                error( 'Unknown overlay type' );
            end
            obj.typeOverlays(obj.numOverlays) = type;
            if ~isa( file, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.fileOverlays(obj.numOverlays) = file;
            if ~isa( offset_s, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.offsetOverlays(obj.numOverlays) = offset_s;
        end
        
        function addWalls( obj, walls )
            if ~isa( walls, 'WallsValGen' ), error( 'Use a WallsValGen' ); end;
            obj.walls(obj.numOverlays) = walls;
        end
        
        function setupWp1Proc( obj, wp1proc )
            if ~isa( wp1proc, 'simulator.SimulatorConvexRoom' )
                error( 'Dont know how to handle other wp1 procs' );
            end
            if ~isempty( obj.walls )
                wp1proc.Walls = obj.walls.genVal();
            end
            wp1proc.Sources{1}.set( 'Azimuth', obj.angleSignal.genVal() );
            wp1proc.set('Init',true);
        end
        
    end
    
end
