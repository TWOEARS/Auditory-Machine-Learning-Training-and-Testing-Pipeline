classdef MultiCondition < handle

    %%
    properties
        angleSignal;
        distSignal;
        numOverlays;
        angleOverlays;
        distOverlays;
        SNRs;
        typeOverlays;
        fileOverlays;
        offsetOverlays;
        walls;
    end

    %%
    methods
        
        %%
        function obj = MultiCondition() % creates a clean MC
            obj.angleSignal = ValGen( 'manual', 0 );
            obj.distSignal = ValGen( 'manual', 3 );
            obj.numOverlays = 0;
            obj.walls = WallsValGen.empty;
            obj.angleOverlays = ValGen.empty;
            obj.distOverlays = ValGen.empty;
            obj.SNRs = ValGen.empty;
            obj.typeOverlays = cell(0);
            obj.fileOverlays = ValGen.empty;
            obj.offsetOverlays= ValGen.empty;
        end
      
        %%
        function addOverlay( obj, angle, dist, SNR, type, file, offset_s )
            obj.numOverlays = obj.numOverlays + 1;
            if ~isa( angle, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.angleOverlays(obj.numOverlays) = angle;
            if ~isa( dist, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.distOverlays(obj.numOverlays) = dist;
            if ~isa( SNR, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.SNRs(obj.numOverlays) = SNR;
            if sum( strcmpi( type, {'point', 'diffuse'} ) ) == 0
                error( 'Unknown overlay type' );
            end
            obj.typeOverlays{obj.numOverlays} = type;
            if ~isa( file, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.fileOverlays(obj.numOverlays) = file;
            if ~isa( offset_s, 'ValGen' ), error( 'Use a ValGen' ); end;
            obj.offsetOverlays(obj.numOverlays) = offset_s;
        end
        
        function addWalls( obj, walls )
            if ~isa( walls, 'WallsValGen' ), error( 'Use a WallsValGen' ); end;
            obj.walls = walls;
        end
        
        %%
        function overlaySound = setupWp1Proc( obj, wp1proc )
            if ~isa( wp1proc, 'simulator.SimulatorConvexRoom' )
                error( 'Dont know how to handle other wp1 procs' );
            end
            wp1proc.set( 'ShutDown', true );
            wp1proc.Sources(2:end) = [];
            if ~isempty( obj.walls )
                wp1proc.Walls = obj.walls.genVal();
                wp1proc.Sources{1} = simulator.source.ISMShoeBox( wp1proc );
            else
                wp1proc.Sources{1} = simulator.source.Point();
            end
            wp1proc.Sources{1}.set( 'Radius', obj.distSignal.genVal() ); 
            wp1proc.Sources{1}.set( 'Azimuth', obj.angleSignal.genVal() );
            wp1proc.Sources{1}.AudioBuffer = simulator.buffer.FIFO(1);

            overlaySound = {};
            for k = 1:obj.numOverlays
                if strcmpi( obj.typeOverlays{k}, 'point' )
                    if ~isempty( obj.walls )
                        wp1proc.Sources{k+1} = simulator.source.ISMShoeBox( wp1proc );
                    else
                        wp1proc.Sources{k+1} = simulator.source.Point();
                    end
                    overlaySound{k} = ...
                        getPointSourceSignalFromWav( ...
                            obj.fileOverlays(k).genVal(), wp1proc.SampleRate, ...
                            obj.offsetOverlays(k).genVal() );
                    channelMapping = [1];
                end
                if strcmpi( obj.typeOverlays{k}, 'diffuse' )
                    wp1proc.Sources{k+1} = simulator.source.Binaural();
                    diffuseMonoSound = ...
                        getPointSourceSignalFromWav( ...
                            obj.fileOverlays(k).genVal(), wp1proc.SampleRate, ...
                            obj.offsetOverlays(k).genVal() );
                    overlaySound{k} = repmat( diffuseMonoSound, 1, 2 );
                    channelMapping = [1 2];
                end
                wp1proc.Sources{k+1}.set( 'Radius', obj.distOverlays(k).genVal() );
                wp1proc.Sources{k+1}.set( 'Azimuth', obj.angleOverlays(k).genVal() );
                wp1proc.Sources{k+1}.AudioBuffer = simulator.buffer.FIFO( channelMapping );
            end
            
            wp1proc.set('Init',true);
        end
        
    end
    
end
