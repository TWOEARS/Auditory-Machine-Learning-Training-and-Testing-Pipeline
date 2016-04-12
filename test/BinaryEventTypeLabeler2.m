classdef BinaryEventTypeLabeler < LabelCreators.MultiEventTypeLabeler
    % class for binary labeling blocks by event (target vs non-target)
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        minBlockToEventRatio;
        maxNegBlockToEventRatio;
        labelBlockSize_s;
        isPosOutType;
        negOut;
        isNegOutType;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = BinaryEventTypeLabeler( varargin )
            obj = obj@LabelCreators.MultiEventTypeLabeler();
            ip = inputParser;
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'maxNegBlockToEventRatio', 0 );
            ip.addOptional( 'labelBlockSize_s', 1.0 );
            ip.addOptional( 'posOutType', {'TypeName'} );
            ip.addOptional( 'negOut', 'all' ); % event, non-event, all
            ip.addOptional( 'negOutType', 'rest' ); % typename, 'rest' (respective to pos)
            ip.parse( varargin{:} );
            multiTypes = {ip.Results.posOutType, };
            multiParams = {'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                           'minBlockToEventRatio', ip.Results.minBlockToEventRatio, ...
                           'maxNegBlockToEventRatio', ip.Results.maxNegBlockToEventRatio, ...
                           'types', multiTypes };
            obj.isPosOutType = @(t)( any( strcmp( ip.Results.posOutType, t ) ) );
            obj.negOut = ip.Results.negOut;
            if strcmp( ip.Results.negOutType, 'rest' )
                obj.isNegOutType = @(t)( ~obj.isPosOutType( t ) );
            else
                obj.isNegOutType = @(t)( any( strcmp( ip.Results.negOutType, t ) ) );
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.labelBlockSize = obj.labelBlockSize_s;
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.maxNegBlockToEventRatio = obj.maxNegBlockToEventRatio;
            outputDeps.isPosOutType = obj.isPosOutType;
            outputDeps.negOut = obj.negOut;
            outputDeps.isNegOutType = obj.isNegOutType;
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
            eventIsPosType = arrayfun( @(ba)(...
                                 obj.isPosOutType( ba ) ...
                                              ), blockAnnotations.objectType.objectType );
            eventIsNegType = arrayfun( @(ba)(...
                                 obj.isNegOutType( ba ) ...
                                              ), blockAnnotations.objectType.objectType );
            [isPosEvent, isNotPosEvent] = obj.isBlockEvent( eventIsPosType, ...
                                                            eventBlockOverlaps, ...
                                                            eventOnsets, eventOffsets );
            [isNegEvent, isNotNegEvent] = obj.isBlockEvent( eventIsNegType, ...
                                                            eventBlockOverlaps, ...
                                                            eventOnsets, eventOffsets );
            if isPosEvent
                y = 1;
            elseif strcmp( obj.negOut, 'event' ) && isNegEvent
                y = -1;
            elseif strcmp( obj.negOut, 'non-event' ) && isNotPosEvent && isNotNegEvent
                y = -1;
            elseif strcmp( obj.negOut, 'all' ) && isNotPosEvent
                y = -1;
            else
                y = 0;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function [isEvent, isNotEvent] = isBlockEvent( obj, isEventConsidered, ...
                                                            eventBlockOverlaps, ...
                                                            eventOnsets, eventOffsets )
            isEventBlockOverlap = isEventConsidered & (eventBlockOverlaps > 0);
            eventBlockOverlapLen = sum( eventBlockOverlaps(isEventBlockOverlap) );
            eventLen = sum( eventOffsets(isEventBlockOverlap) ...
                            - eventOnsets(isEventBlockOverlap) );
            maxBlockEventLen = min( obj.labelBlockSize_s, eventLen );
            relEventBlockOverlap = eventBlockOverlapLen / maxBlockEventLen;
            isEvent = relEventBlockOverlap >= obj.minBlockToEventRatio;
            isNotEvent = relEventBlockOverlap <= obj.maxNegBlockToEventRatio;
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

