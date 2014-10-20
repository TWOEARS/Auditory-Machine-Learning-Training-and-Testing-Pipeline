classdef (Abstract) IdWp1ProcInterface < IdProcInterface
    %% responsible for transforming wav files into earsignals
    %   this includes transforming onset/offset labels to the earsignals'
    %   time line, as it is the only point where the "truth" is known.
    
    %%---------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdWp1ProcInterface()
            obj = obj@IdProcInterface();
        end
        
        %% function run( obj )
        %       wp1-process all wavs in idTrainData
        %       save the results in mat-files
        %       updates idTrainData
        function run( obj )
            fprintf( 'wp1 processing of sounds' );
            for trainFile = obj.data(:)'
                fprintf( '\n.' );
                wp1FileName = obj.buildProcFileName( trainFile.wavFileName );
                if exist( wp1FileName, 'file' ), continue; end
                [earSignals, earsOnOffs] = obj.makeEarsignalsAndLabels( trainFile.wavFileName );
                save( wp1FileName, 'earSignals', 'earsOnOffs' );
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
        
        [earSignals, earsOnOffs] = makeEarsignalsAndLabels( obj, trainFile )
        
    end
    
end

