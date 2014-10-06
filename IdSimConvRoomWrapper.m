classdef IdSimConvRoomWrapper < IdWp1ProcInterface

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        convRoomSim;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdSimConvRoomWrapper( simConvRoomXML )
            obj = obj@IdWp1ProcInterface();
            obj.convRoomSim = simulator.SimulatorConvexRoom( simConvRoomXML, true );
        end
        
        function delete( obj )
            obj.convRoomSim.set('ShutDown',true);
        end
        
        %%-----------------------------------------------------------------

        function signals = makeEarsignals( obj, trainFile )
            monoSound = getPointSourceSignalFromWav( ...
                trainFile.wavFileName, obj.convRoomSim.SampleRate, 0 );
            obj.convRoomSim.Sources{1}.set('Azimuth', 0);
            obj.convRoomSim.set('ReInit',true);
            obj.convRoomSim.Sources{1}.setData( monoSound );
            obj.convRoomSim.Sinks.removeData();
            while ~obj.convRoomSim.Sources{1}.isEmpty()
                obj.convRoomSim.set('Refresh',true);  % refresh all objects
                obj.convRoomSim.set('Process',true);  % processing
                fprintf( '.' );
            end
            signals = obj.convRoomSim.Sinks.getData();
            signals = signals / max( abs( signals(:) ) ); % normalize
        end

    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
        

    end
    
    
end

% function wp2processSounds( dfiles, esetup )
% 
% disp( 'wp2 processing of sounds' );
% 
% wp2DataHash = getWp2dataHash( esetup );
% 
% for k = 1:length( dfiles.soundFileNames )
%     
%     wp2SaveName = [dfiles.soundFileNames{k} '.' wp2DataHash '.wp2.mat'];
%     if exist( wp2SaveName, 'file' )
%         fprintf( '.' );
%         continue;
%     end;
%     
%     fprintf( '\n%s', wp2SaveName );
% 
%     wp2data = [];
%     for angle = esetup.wp2dataCreation.angle
%         
%         fprintf( '.' );
%         
%         dObj = [];
%         mObj = [];
%         wp2procs = [];
%         dObj = dataObject( [], esetup.wp2dataCreation.fs, 2, 1 );
%         mObj = manager( dObj );
%         for z = 1:length( esetup.wp2dataCreation.requests )
%             wp2procs{z} = mObj.addProcessor( esetup.wp2dataCreation.requests{z}, esetup.wp2dataCreation.requestP{z} );
%         end
%         tmpData = cell( size(wp2procs,2), size(wp2procs{1},2) );
%         for pos = 1:esetup.wp2dataCreation.fs:length(earSignals)
%             posEnd = min( length( earSignals ), pos + esetup.wp2dataCreation.fs - 1 );
%             mObj.processChunk( earSignals(pos:posEnd,:), 0 );
%             for z = 1:size(wp2procs,2)
%                 for zz = 1:size(wp2procs{z},2)
%                     tmpData{z,zz} = [tmpData{z,zz}; wp2procs{z}{zz}.Data];
%                 end
%             end
%             fprintf( '.' );
%         end
%         for z = 1:size(wp2procs,2)
%             for zz = 1:size(wp2procs{z},2)
%                 wp2procs{z}{zz}.Data = tmpData{z,zz};
%             end
%         end
%         wp2data = [wp2data wp2procs(:)];
%     end
%     
%     save( wp2SaveName, 'wp2data', 'esetup' );
% 
% end
% 
% 
% disp( ';' );
