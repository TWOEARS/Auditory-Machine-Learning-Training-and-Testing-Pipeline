classdef Wp2Module < IdWp2ProcInterface
    
    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        managerObject;           % WP2 manager object - holds the signal buffer (data obj)
        outputSignals;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = Wp2Module()
            obj = obj@IdWp2ProcInterface();
        end
        
        function hashMembers = getHashObjects( obj )
            hashMembers = {obj.managerObject.Data.getParameterSummary( obj.managerObject ) };
        end

        %%-----------------------------------------------------------------

        function init( obj, fs, wp2Requests )
            wp2dataObj = dataObject( [], fs, 2, 1 );
            obj.managerObject = manager( wp2dataObj );
            for ii = 1:length( wp2Requests )
                obj.outputSignals{ii} = obj.managerObject.addProcessor( ...
                    wp2Requests{ii}.name, wp2Requests{ii}.params );
            end
        end
        
        %%-----------------------------------------------------------------

        function run( obj )
            fprintf( 'wp2 processing' );
            for trainFile = obj.data(:)'
                fprintf( '\n.' );
                wp2FileName = obj.buildProcFileName( trainFile.wavFileName );
                if exist( wp2FileName, 'file' ), continue; end
                wp2data = obj.makeWp2Data( obj.buildWp1FileName( trainFile.wavFileName ) );
                save( wp2FileName, 'wp2data' );
            end
            fprintf( ';\n' );
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
        
        function wp2data = makeWp2Data( obj, wp1fileName )
            
        end
        
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
%
%     save( wp2SaveName, 'wp2data', 'esetup' );
%
% end
%
%
% disp( ';' );