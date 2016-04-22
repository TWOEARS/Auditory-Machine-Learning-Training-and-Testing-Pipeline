classdef BinaryEventTypeLabeler < LabelCreators.MultiEventTypeLabeler
    % class for binary labeling blocks by event (target vs non-target)
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        negOut;
        negOutType;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = BinaryEventTypeLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'maxNegBlockToEventRatio', 0 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'posOutType', {'TypeName'} );
            ip.addOptional( 'negOut', 'all' ); % event, non-event, all
            ip.addOptional( 'negOutType', 'rest' ); % typename, 'rest' (respective to pos)
            ip.parse( varargin{:} );
            multiTypes = {ip.Results.posOutType, {}};
            multiParams = {'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                           'minBlockToEventRatio', ip.Results.minBlockToEventRatio, ...
                           'maxNegBlockToEventRatio', ip.Results.maxNegBlockToEventRatio, ...
                           'types', multiTypes };
            obj = obj@LabelCreators.MultiEventTypeLabeler( multiParams{:} );
            obj.negOut = ip.Results.negOut;
            obj.negOutType = ip.Results.negOutType;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        % override of LabelCreators.MultiEventTypeLabeler's method
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.negOut = obj.negOut;
            outputDeps.negOutType = obj.negOutType;
            outputDeps.internMulti = ...
                getLabelInternOutputDependencies@LabelCreators.MultiEventTypeLabeler( obj );
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------
        
        function eit = eventIsType( obj, typeIdx, type )
            if typeIdx == 1
                eit = eventIsType@LabelCreators.MultiEventTypeLabeler( obj, 1, type );
            else
                if strcmp( obj.negOutType, 'rest' )
                    eit = ~eventIsType@LabelCreators.MultiEventTypeLabeler( obj, 1, type );
                else
                    eit = eventIsType@LabelCreators.MultiEventTypeLabeler( obj, 2, type );
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of LabelCreators.MultiEventTypeLabeler's method
        function y = label( obj, blockAnnotations )
            relBlockEventOverlap = obj.relBlockEventsOverlap( blockAnnotations );
            if relBlockEventOverlap(1) > obj.minBlockToEventRatio
                y = 1;
            elseif strcmp( obj.negOut, 'event' ) && ...
                    (relBlockEventOverlap(2) > obj.minBlockToEventRatio)
                y = -1;
            elseif strcmp( obj.negOut, 'non-event' ) && ...
                    (max( relBlockEventOverlap ) < obj.maxNegBlockToEventRatio) 
                y = -1;
            elseif strcmp( obj.negOut, 'all' ) && ...
                    (relBlockEventOverlap(1) < obj.maxNegBlockToEventRatio) 
                y = -1;
            else
                y = NaN;
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

