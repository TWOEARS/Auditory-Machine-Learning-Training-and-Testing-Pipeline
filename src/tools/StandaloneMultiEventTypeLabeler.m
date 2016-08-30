classdef StandaloneMultiEventTypeLabeler
    % class for multi-class labeling blocks by event
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        minBlockToEventRatio;
        types;
        labelBlockSize_s;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = StandaloneMultiEventTypeLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.addOptional( 'labelBlockSize_s', 0.5 );
            ip.parse( varargin{:} );
            obj.minBlockToEventRatio = ip.Results.minBlockToEventRatio;
            obj.types = ip.Results.types;
            obj.labelBlockSize_s = ip.Results.labelBlockSize_s;
        end
        
        %% -------------------------------------------------------------------------------
        function y = label( obj, blockAnnotations )
            [activeTypes, ~, ~] = getActiveTypes( obj, blockAnnotations );
            y = activeTypes;
        end
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        %% -------------------------------------------------------------------------------
        
        function eit = eventIsType( obj, typeIdx, type )
            eit = any( strcmp( type, obj.types{typeIdx} ) );
        end
        %% -------------------------------------------------------------------------------
        
        %% -------------------------------------------------------------------------------
        function [activeTypes, relBlockEventOverlap, srcIdxs] = getActiveTypes( obj, blockAnnotations )
            [relBlockEventOverlap, srcIdxs] = obj.relBlockEventsOverlap( blockAnnotations );
            activeTypes = relBlockEventOverlap >= obj.minBlockToEventRatio;
        end
        
        function [relBlockEventsOverlap, srcIdxs] = relBlockEventsOverlap( obj, blockAnnotations )
            blockOffset = blockAnnotations.blockOffset;
            labelBlockOnset = blockOffset - obj.labelBlockSize_s;
            eventOnsets = blockAnnotations.srcType.t.onset;
            eventOffsets = blockAnnotations.srcType.t.offset;
            relBlockEventsOverlap = zeros( size( obj.types ) );
            srcIdxs = cell( size( obj.types ) );
            for ii = 1 : numel( obj.types )
                eventsAreType = cellfun( @(ba)(...
                                  obj.eventIsType( ii, ba )...
                                              ), blockAnnotations.srcType.srcType(:,1) );
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
                srcIdxs{ii} = unique( [blockAnnotations.srcType.srcType{eventsAreType,2}] );
            end
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
end