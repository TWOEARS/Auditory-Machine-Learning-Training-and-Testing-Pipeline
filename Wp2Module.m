classdef Wp2Module < IdWp2ProcInterface
    
    %%---------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = Wp2Module()
            obj = obj@IdWp2ProcInterface();
        end
        
        %%-----------------------------------------------------------------

        function registerRequests( obj, wp2Requests )
        end

        %%-----------------------------------------------------------------

        function run( obj, idTrainData )
            fprintf( 'wp2 processing' );
            idTrainData.wp2Hash = obj.getHash();
            wp2FileNameExt = ['.' idTrainData.wp1Hash '.' idTrainData.wp2Hash '.wp2.mat'];
            for trainFile = idTrainData(:)'
                fprintf( '\n.' );
                wp2FileName = [which(trainFile.wavFileName) wp2FileNameExt];
                if exist( wp2FileName, 'file' ), continue; end
                wp1FileNameExt = ['.' idTrainData.wp1Hash '.wp1.mat'];
                wp1FileName = [which(trainFile.wavFileName) wp1FileNameExt];
                wp2data = obj.makeWp2Data( [trainFile.wavFileName wp1FileNameExt] );
                save( wp2FileName, 'wp2data' );
            end
            fprintf( ';\n' );
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