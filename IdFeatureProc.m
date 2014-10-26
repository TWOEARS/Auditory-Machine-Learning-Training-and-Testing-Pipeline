classdef IdFeatureProc < IdProcInterface

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        blockSize_s;
        shiftSize_s;
        minBlockToEventRatio;
        featureProc;
        x;
        y;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdFeatureProc( featureProc )
            if ~isa( featureProc, 'FeatureProcInterface' )
                error( 'FeatureProcessor must implement FeatureProcInterface.' );
            end
            obj = obj@IdProcInterface();
            obj.blockSize_s = 0.5;
            obj.shiftSize_s = 0.25;
            obj.minBlockToEventRatio = 0.5;
            obj.featureProc = featureProc;
        end
        %% ----------------------------------------------------------------
        
        function process( obj, inputFileName )
            in = load( inputFileName );
            [afeBlocks, obj.y] = obj.blockifyAndLabel( in.afeData, in.onOffsOut );
            obj.x = [];
            for afeBlock = afeBlocks
                obj.x(end+1,:) = obj.featureProc.makeDataPoint( afeBlock{1} );
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.blockSize = obj.blockSize_s;
            outputDeps.shiftSize = obj.shiftSize_s;
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.featureProc = obj.featureProc.getInternOutputDependencies();
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.x = obj.x;
            out.y = obj.y;
        end
        %% ----------------------------------------------------------------

        function [afeBlocks, y] = blockifyAndLabel( obj, afeData, onOffs_s )
            afeBlocks = {};
            y = [];
            afeDataNames = afeData.keys;
            anyAFEsignal = afeData(afeDataNames{1});
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            sigLen = double( length( anyAFEsignal.Data ) ) / anyAFEsignal.FsHz;
            for backOffset = 0.0:obj.shiftSize_s:sigLen
                afeBlock = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
                for afeDataKey = afeDataNames
                    afeSignal = afeData(afeDataKey{1});
                    if isa( afeSignal, 'cell' )
                        afeSignalExtract{1} = afeSignal{1}.cutSignalCopy( obj.blockSize_s, backOffset );
                        afeSignalExtract{1}.reduceBufferToArray();
                        afeSignalExtract{2} = afeSignal{2}.cutSignalCopy( obj.blockSize_s, backOffset );
                        afeSignalExtract{2}.reduceBufferToArray();
                    else
                        afeSignalExtract = afeSignal.cutSignalCopy( obj.blockSize_s, backOffset );
                    end
                    afeBlock(afeDataKey{1}) = afeSignalExtract;
                    fprintf( '.' );
                end
                afeBlocks{end+1} = afeBlock;
                blockOffset = sigLen - backOffset;
                blockOnset = blockOffset - obj.blockSize_s;
                y(end+1) = 0;
                for jj = 1 : size( onOffs_s, 1 )
                    eventOnset = onOffs_s(jj,1);
                    eventOffset = onOffs_s(jj,2);
                    eventLength = eventOffset - eventOnset;
                    maxBlockEventLen = min( obj.blockSize_s, eventLength );
                    eventBlockOverlapLen = min( blockOffset, eventOffset ) - max( blockOnset, eventOnset );
                    relEventBlockOverlap = eventBlockOverlapLen / maxBlockEventLen;
                    blockIsSoundEvent = relEventBlockOverlap > obj.minBlockToEventRatio;
                    y(end) = y(end) || blockIsSoundEvent;
                    if y(end) == 1, break, end;
                end
            end
            afeBlocks = fliplr( afeBlocks );
            y = fliplr( y );
            y = y';
            %scaling to [-1..1]
            y = (y * 2) - 1;
        end
        %% ----------------------------------------------------------------
        
    end
    
end

