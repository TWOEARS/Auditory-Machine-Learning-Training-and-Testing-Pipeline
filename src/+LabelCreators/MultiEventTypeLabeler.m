classdef MultiEventTypeLabeler < LabelCreators.Base
    % class for binary labeling blocks by event (target vs non-target)
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        minBlockToEventRatio;
        maxNegBlockToEventRatio;
        labelBlockSize_s;
        types;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MultiEventTypeLabeler( varargin )
            obj = obj@LabelCreators.Base();
            ip = inputParser;
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'maxNegBlockToEventRatio', 0 );
            ip.addOptional( 'labelBlockSize_s', 1.0 );
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.parse( varargin{:} );
            obj.labelBlockSize_s = ip.Results.labelBlockSize_s;
            obj.minBlockToEventRatio = ip.Results.minBlockToEventRatio;
            obj.maxNegBlockToEventRatio = ip.Results.maxNegBlockToEventRatio;
            obj.types = ip.Results.types;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.labelBlockSize = obj.labelBlockSize_s;
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.maxNegBlockToEventRatio = obj.maxNegBlockToEventRatio;
            outputDeps.types = obj.types;
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
            blockOffset = blockAnnotations.blockOffset;
            labelBlockOnset = blockOffset - obj.labelBlockSize_s;
            eventOnsets = blockAnnotations.objectType.t.onset;
            eventOffsets = blockAnnotations.objectType.t.offset;
            eventBlockOverlaps = arrayfun( @(eon,eof)(...
                                  min( blockOffset, eof ) - max( labelBlockOnset, eon )...
                                                           ), eventOnsets, eventOffsets );
            relBlockEventOverlap = zeros( size( obj.types ) );
            for ii = 1 : numel( obj.types )
                eventIsType = arrayfun( @(ba)(...
                                  any( strcmp( ba, obj.types{ii} ) )...
                                              ), blockAnnotations.objectType.objectType );
                relBlockEventOverlap(ii) = obj.relBlockEventOverlap( eventIsType, ...
                                                                     eventBlockOverlaps, ...
                                                                     eventOnsets, eventOffsets );
            end
            [maxRelOverlap, maxIdx] = max( relBlockEventOverlap );
            if maxRelOverlap < obj.maxBlockToEventRatio
                y = -1;
            elseif maxRelOverlap < obj.minBlockToEventRatio
                y = 0;
            else
                y = maxIdx;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function relOverlap = relBlockEventOverlap( obj, isEventConsidered, ...
                                                         eventBlockOverlaps, ...
                                                         eventOnsets, eventOffsets )
            isEventBlockOverlap = isEventConsidered & (eventBlockOverlaps > 0);
            eventBlockOverlapLen = sum( eventBlockOverlaps(isEventBlockOverlap) );
            eventLen = sum( eventOffsets(isEventBlockOverlap) ...
                            - eventOnsets(isEventBlockOverlap) );
            maxBlockEventLen = min( obj.labelBlockSize_s, eventLen );
            relOverlap = eventBlockOverlapLen / maxBlockEventLen;
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

