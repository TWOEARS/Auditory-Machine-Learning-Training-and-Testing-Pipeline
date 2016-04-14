classdef AzmLabeler < LabelCreators.EnergyDependentLabeler
    % class for labeling blocks by azm of a specified source
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = AzmLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'sourceMinEnergy', -20 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'sourceId', 1 );
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.EnergyDependentLabeler( ...
                                      'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                                      'sourcesMinEnergy', ip.Results.sourceMinEnergy, ...
                                      'sourcesId', ip.Results.sourceId );
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------

        function y = labelEnergeticBlock( obj, blockAnnotations )
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

        

