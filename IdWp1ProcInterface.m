classdef (Abstract) IdWp1ProcInterface < Hashable
    
    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        hash;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdWp1ProcInterface()
        end
        
        %% function run( obj, idTrainData )
        %       wp1-process all wavs in idTrainData
        %       save the results in mat-files
        %       updates idTrainData
        function run( obj, idTrainData )
            fprintf( 'wp1 processing of sounds' );
            obj.hash = obj.getHash( 10 );
            for trainFile = idTrainData(:)'
                fprintf( '\n.' );
                if ~isempty( trainFile.wp1FileName ) ...
                        && exist( trainFile.wp1FileName, 'file' )
                    continue;
                end
                earSignals = obj.makeEarsignals( trainFile );
            end
            fprintf( ';\n' );
        end
        
        
        %%-----------------------------------------------------------------
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        
        signals = makeEarsignals( obj, trainFile )
        
    end
    
end

