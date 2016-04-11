classdef BinaryEventTypeLabeler < LabelCreators.Base
    % class for binary labeling blocks by event (target vs non-target)
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        minBlockToEventRatio;
        maxNegBlockToEventRatio;
        labelBlockSize_s;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = BinaryEventTypeLabeler( minBlockToEventRatio, labelBlockSize_s )
            obj = obj@LabelCreators.Base();
            obj.minBlockToEventRatio = minBlockToEventRatio;
            obj.labelBlockSize_s = labelBlockSize_s;
            obj.maxNegBlockToEventRatio = 0;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.labelBlockSize = obj.labelBlockSize_s;
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.maxNegBlockToEventRatio = obj.maxNegBlockToEventRatio;
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------

        % override of LabelCreators.Base's method
        function out = getOutput( obj )
            out = getOutput@LabelCreators.Base( obj );
            out.x = out.x(out.y ~= 0);
            out.a = out.blockAnnotations(out.y ~= 0);
            out.y = out.y(out.y ~= 0);
        end
        %% -------------------------------------------------------------------------------
        
        function y = label( obj, blockAnnotations )
            labelBlockOnset = blockOffset - obj.labelBlockSize_s;
            y(end+1) = -1;
            eventBlockOverlapLen = 0;
            eventLength = 0;
            for jj = 1 : size( blockAnnotations, 1 )
                thisEventOnset = blockAnnotations(jj,1);
                if thisEventOnset >= blockOffset, continue; end
                thisEventOffset = blockAnnotations(jj,2);
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
                y(end) = 1;
            elseif blockIsNoClearNegative
                y(end) = 0;
            end;
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

