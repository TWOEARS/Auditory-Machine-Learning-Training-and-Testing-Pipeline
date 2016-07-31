classdef MultiEventTypeLabeler < LabelCreators.Base
    % class for multi-class labeling blocks by event
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        minBlockToEventRatio;
        maxNegBlockToEventRatio;
        types;
        negOut;
        srcPrioMethod;
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
            ip.addOptional( 'negOut', 'rest' ); % rest, none
            ip.addOptional( 'srcPrioMethod', 'order' ); % energy, order, time
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.Base( 'labelBlockSize_s', ip.Results.labelBlockSize_s );
            obj.minBlockToEventRatio = ip.Results.minBlockToEventRatio;
            obj.maxNegBlockToEventRatio = ip.Results.maxNegBlockToEventRatio;
            obj.types = ip.Results.types;
            obj.negOut = ip.Results.negOut;
            obj.srcPrioMethod = ip.Results.srcPrioMethod;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.maxNegBlockToEventRatio = obj.maxNegBlockToEventRatio;
            outputDeps.types = obj.types;
            outputDeps.negOut = obj.negOut;
            outputDeps.srcPrioMethod = obj.srcPrioMethod;
            outputDeps.v = 5;
        end
        %% -------------------------------------------------------------------------------
        
        function eit = eventIsType( obj, typeIdx, type )
            eit = any( strcmp( type, obj.types{typeIdx} ) );
        end
        %% -------------------------------------------------------------------------------
        
        function y = label( obj, blockAnnotations )
            [relBlockEventOverlap, srcIdxs] = obj.relBlockEventsOverlap( blockAnnotations );
            [maxPosRelOverlap,maxTimeTypeIdx] = max( relBlockEventOverlap );
            activeTypes = relBlockEventOverlap >= obj.minBlockToEventRatio;
            if any( activeTypes )
                switch obj.srcPrioMethod
                    case 'energy'
                        eSrcs = cellfun( @mean, blockAnnotations.srcEnergy(:,:) ); % mean over channels
                        for ii = 1 : numel( activeTypes )
                            if activeTypes(ii)
                                eTypes(ii) = 1/sum( 1./eSrcs([srcIdxs{ii}]) );
                            else
                                eTypes(ii) = -inf;
                            end
                        end
                        [~,labelTypeIdx] = max( eTypes );
                    case 'order'
                        labelTypeIdx = find( activeTypes, 1, 'first' );
                    case 'time'
                        labelTypeIdx = maxTimeTypeIdx;
                    otherwise
                        error( 'AMLTTP:unknownOptionValue', ['%s: unknown option value.'...
                                     'Use ''energy'' or ''order''.'], obj.srcPrioMethod );
                end
                y = labelTypeIdx;
            elseif strcmp( obj.negOut, 'rest' ) && ...
                    (maxPosRelOverlap <= obj.maxNegBlockToEventRatio) 
                y = -1;
            else
                y = NaN;
            end
        end
        %% -------------------------------------------------------------------------------
        
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
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

