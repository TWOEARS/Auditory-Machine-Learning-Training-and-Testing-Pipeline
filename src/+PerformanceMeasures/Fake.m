classdef Fake < PerformanceMeasures.Base
    % Fake performanceMeasure that stores a given performance for pipe
    %   Is just a container class that stores a performance, to fit into 
    %   the pipeline. The calculation has to be done in the model trainer. 

    
    %% --------------------------------------------------------------------
    methods
        
        function obj = Fake(perf, yTrue, yPred, datapointInfo )
            if ~exist('perf', 'var')
                error('This measure requires the parameter <performance>')
            end
            
            if nargin < 3 
                error( 'Not enough input arguments' );
            end
            
            if nargin < 4
                dpiarg = {};
            else
                dpiarg = {datapointInfo};
            end
            % call is required due to inheritance but does nothing
            obj = obj@PerformanceMeasures.Base( yTrue, yPred, dpiarg{:} );
            
            obj.performance = perf;            
        end
        % -----------------------------------------------------------------
    
        function b = eqPm( obj, otherPm )
            b = obj.performance == otherPm.performance;
        end
        % -----------------------------------------------------------------
    
        function b = gtPm( obj, otherPm )
            b = obj.performance > otherPm.performance;
        end
        % -----------------------------------------------------------------
    
        function d = double( obj )
            for ii = 1 : size( obj, 2 )
                d(ii) = double( obj(ii).performance );
            end
        end
        % -----------------------------------------------------------------
    
        function s = char( obj )
            if numel( obj ) > 1
                warning( 'only returning first object''s performance' );
            end
            s = num2str( obj(1).performance );
        end
        % -----------------------------------------------------------------
        
        function [obj, performance, dpi] = calcPerformance( obj, yTrue, yPred, dpi )
            % has to be implemented due to inheritance
            performance = 0;
            dpi = struct.empty;
        end
        
    end

end

