classdef MultiEventTypeLabeler < LabelCreators.Base
    % class for multi-class labeling blocks by event
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        minBlockToEventRatio;
        maxNegBlockToEventRatio;
        eventIsType;
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
            for ii = 1 : numel( ip.Results.types )
                obj.eventIsType{ii} = @(e)(any( strcmp( e, ip.Results.types{ii} ) ));
            end
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

        % override of LabelCreators.Base's method
        function out = getOutput( obj )
            out = getOutput@LabelCreators.Base( obj );
            out.x = out.x(out.y ~= 0);
            out.a = out.blockAnnotations(out.y ~= 0);
            out.y = out.y(out.y ~= 0);
        end
        %% -------------------------------------------------------------------------------
        
        function y = label( obj, blockAnnotations )
            relBlockEventOverlap = obj.relBlockEventsOverlap( blockAnnotations );
            [maxRelOverlap, maxIdx] = max( relBlockEventOverlap );
            if maxRelOverlap < obj.maxNegBlockToEventRatio
                y = -1;
            elseif maxRelOverlap < obj.minBlockToEventRatio
                y = 0;
            else
                y = maxIdx;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function relBlockEventsOverlap = relBlockEventsOverlap( obj, blockAnnotations )
            blockOffset = blockAnnotations.blockOffset;
            labelBlockOnset = blockOffset - obj.labelBlockSize_s;
            eventOnsets = blockAnnotations.objectType.t.onset;
            eventOffsets = blockAnnotations.objectType.t.offset;
            eventBlockOverlaps = arrayfun( @(eon,eof)(...
                                  min( blockOffset, eof ) - max( labelBlockOnset, eon )...
                                                           ), eventOnsets, eventOffsets );
            relBlockEventsOverlap = zeros( size( obj.eventIsType ) );
            for ii = 1 : numel( obj.types )
                eventsAreType = arrayfun( @(ba)(...
                                  obj.eventIsType{ii}(ba)...
                                              ), blockAnnotations.objectType.objectType );
                isEventBlockOverlap = eventsAreType & (eventBlockOverlaps > 0);
                eventBlockOverlapLen = sum( eventBlockOverlaps(isEventBlockOverlap) );
                eventLen = sum( eventOffsets(isEventBlockOverlap) ...
                  - eventOnsets(isEventBlockOverlap) );
                maxBlockEventLen = min( obj.labelBlockSize_s, eventLen );
                relBlockEventsOverlap(ii) = eventBlockOverlapLen / maxBlockEventLen;
            end
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

