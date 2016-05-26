classdef MultiEventTypeLabeler < LabelCreators.Base
    % class for multi-class labeling blocks by event
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        minBlockToEventRatio;
        maxNegBlockToEventRatio;
        types;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MultiEventTypeLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'maxNegBlockToEventRatio', 0 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.Base( 'labelBlockSize_s', ip.Results.labelBlockSize_s );
            obj.minBlockToEventRatio = ip.Results.minBlockToEventRatio;
            obj.maxNegBlockToEventRatio = ip.Results.maxNegBlockToEventRatio;
            obj.types = ip.Results.types;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.maxNegBlockToEventRatio = obj.maxNegBlockToEventRatio;
            outputDeps.types = obj.types;
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------
        
        function eit = eventIsType( obj, typeIdx, type )
            eit = any( strcmp( type, obj.types{typeIdx} ) );
        end
        %% -------------------------------------------------------------------------------
        
        function y = label( obj, blockAnnotations )
            relBlockEventOverlap = obj.relBlockEventsOverlap( blockAnnotations );
            [maxRelOverlap, maxIdx] = max( relBlockEventOverlap );
            if maxRelOverlap < obj.maxNegBlockToEventRatio
                y = -1;
            elseif maxRelOverlap < obj.minBlockToEventRatio
                y = NaN;
            else
                y = maxIdx;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function relBlockEventsOverlap = relBlockEventsOverlap( obj, blockAnnotations )
            blockOffset = blockAnnotations.blockOffset;
            labelBlockOnset = blockOffset - obj.labelBlockSize_s;
            eventOnsets = blockAnnotations.srcType.t.onset;
            eventOffsets = blockAnnotations.srcType.t.offset;
            relBlockEventsOverlap = zeros( size( obj.types ) );
            for ii = 1 : numel( obj.types )
                eventsAreType = cellfun( @(ba)(...
                                  obj.eventIsType( ii, ba )...
                                              ), blockAnnotations.srcType.srcType );
                thisTypeEventOnOffs = ...
                               [eventOnsets(eventsAreType)' eventOffsets(eventsAreType)'];
                thisTypeMergedEventOnOffs = sortAndMergeOnOffs( thisTypeEventOnOffs );
                thisTypeMergedOnsets = thisTypeMergedEventOnOffs(:,1);
                thisTypeMergedOffsets = thisTypeMergedEventOnOffs(:,2);
                eventBlockOverlaps = arrayfun( @(eon,eof)(...
                                  min( blockOffset, eof ) - max( labelBlockOnset, eon )...
                                         ), thisTypeMergedOnsets, thisTypeMergedOffsets );
                isEventBlockOverlap = eventBlockOverlaps' > 0;
                eventBlockOverlapLen = sum( eventBlockOverlaps(isEventBlockOverlap) );
                if eventBlockOverlapLen == 0
                    relBlockEventsOverlap(ii) = 0;
                else
                    eventLen = sum( thisTypeMergedOffsets(isEventBlockOverlap) ...
                                            - thisTypeMergedOnsets(isEventBlockOverlap) );
                    maxBlockEventLen = min( obj.labelBlockSize_s, eventLen );
                    relBlockEventsOverlap(ii) = eventBlockOverlapLen / maxBlockEventLen;
                end
            end
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

