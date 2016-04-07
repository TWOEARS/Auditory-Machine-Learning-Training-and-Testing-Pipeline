classdef StandardBlockCreator < BlockCreators.Base
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = StandardBlockCreator( blockSize_s, shiftSize_s )
            obj = obj@BlockCreators.Base( blockSize_s, shiftSize_s );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.v = 1;
        end
        %% ------------------------------------------------------------------------------- 

        function [afeBlocks, blockAnnotations] = blockify( obj, afeData, annotations )
            afeBlocks = {};
            blockAnnotations = [];
            afeDataNames = afeData.keys;
            anyAFEsignal = afeData(afeDataNames{1});
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            sigLen = double( length( anyAFEsignal.Data ) ) / anyAFEsignal.FsHz;
            for backOffset_s = 0.0 : obj.shiftSize_s : max(sigLen+0.01,obj.shiftSize_s) - obj.shiftSize_s
                afeBlocks{end+1} = obj.cutDataBlock( afeData, backOffset_s );
                blockOffset = sigLen - backOffset_s;
                labelBlockOnset = blockOffset - obj.labelBlockSize_s;
                blockAnnotations(end+1) = -1;
                eventBlockOverlapLen = 0;
                eventLength = 0;
                for jj = 1 : size( onOffs_s, 1 )
                    thisEventOnset = onOffs_s(jj,1);
                    if thisEventOnset >= blockOffset, continue; end
                    thisEventOffset = onOffs_s(jj,2);
                    if thisEventOffset <= labelBlockOnset, continue; end
                    thisEventBlockOverlapLen = ...
                        min( blockOffset, thisEventOffset ) - ...
                        max( labelBlockOnset, thisEventOnset );
                    isEventBlockOverlap = thisEventBlockOverlapLen > 0;
                    if isEventBlockOverlap
                        eventBlockOverlapLen = ...
                            eventBlockOverlapLen + thisEventBlockOverlapLen;
                        eventLength = eventLength + thisEventOffset - thisEventOnset;
                    end
                end
                maxBlockEventLen = min( obj.labelBlockSize_s, eventLength );
                relEventBlockOverlap = eventBlockOverlapLen / maxBlockEventLen;
                blockIsSoundEvent = relEventBlockOverlap > obj.minBlockToEventRatio;
                blockIsNoClearNegative = relEventBlockOverlap > obj.maxNegBlockToEventRatio;
                if blockIsSoundEvent
                    blockAnnotations(end) = 1;
                    if isfield( annotations, 'srcEnergy' ) ...
                            && size( annotations.srcEnergy, 1 ) > 1
                        energyFramesInBlockIdxs = ...
                            annotations.srcEnergy_t >= blockOffset - obj.blockSize_s ...
                            & annotations.srcEnergy_t <= blockOffset;
                        energyFramesInBlock = ...
                            annotations.srcEnergy(2:end,:,energyFramesInBlockIdxs);
                        distBlockEnergy = ...
                            sum( log(30) - log( -mean( mean( energyFramesInBlock, 3 ), 2 ) ) );
                        if distBlockEnergy < 0, blockAnnotations(end) = 0; end
                    end
                elseif blockIsNoClearNegative
                    blockAnnotations(end) = 0;
                end;
            end
            afeBlocks = fliplr( afeBlocks );
            blockAnnotations = fliplr( blockAnnotations );
            blockAnnotations = blockAnnotations';
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

