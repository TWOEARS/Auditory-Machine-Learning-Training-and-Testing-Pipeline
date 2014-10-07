classdef (Abstract) IdWp1ProcInterface < Hashable
    %% responsible for transforming wav files into earsignals
    %   this includes transforming onset/offset labels to the earsignals'
    %   time line, as it is the only point where the "truth" is known.
    
    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        hash;
        wp1NameExt;
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
            obj.wp1NameExt = ['.' obj.hash '.wp1.mat'];
            for trainFile = idTrainData(:)'
                fprintf( '\n.' );
                if ~isempty( trainFile.wp1FileName ) ...
                        && exist( trainFile.wp1FileName, 'file' )
                    continue;
                end
                [earSignals, earsLabels] = obj.makeEarsignalsAndLabels( trainFile );
                trainFile.wp1FileName = [trainFile.wavFileName wp1NameExt];
                save( [which(trainFile.wavFileName) wp1NameExt], 'earSignals', earsLabels );
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
        
        [earSignals, earsLabels] = makeEarsignalsAndLabels( obj, trainFile )
        
    end
    
end

