classdef (Abstract) FeatureProcInterface < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        blockSize_s;
    end
    
    %% --------------------------------------------------------------------
    methods (Abstract)
        afeRequests = getAFErequests( obj )
        outputDeps = getInternOutputDependencies( obj )
        x = makeDataPoint( obj, afeData )
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = FeatureProcInterface( blockSize_s )
            obj.blockSize_s = blockSize_s;
        end
        %% ----------------------------------------------------------------

        
        function afeBlock = cutDataBlock( obj, afeData, backOffset_s )
            afeBlock = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            for afeKey = afeData.keys
                afeSignal = afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    afeSignalExtract{1} = afeSignal{1}.cutSignalCopy( obj.blockSize_s, backOffset_s );
                    afeSignalExtract{1}.reduceBufferToArray();
                    afeSignalExtract{2} = afeSignal{2}.cutSignalCopy( obj.blockSize_s, backOffset_s );
                    afeSignalExtract{2}.reduceBufferToArray();
                else
                    afeSignalExtract = afeSignal.cutSignalCopy( obj.blockSize_s, backOffset_s );
                    afeSignalExtract.reduceBufferToArray();
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
                fprintf( '.' );
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
end

