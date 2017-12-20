classdef BAC2 < PerformanceMeasures.BAC
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        bac;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC2( yTrue, yPred, datapointInfo )
           if nargin < 3
                dpiarg = {};
            else
                dpiarg = {datapointInfo};
            end
            obj = obj@PerformanceMeasures.BAC( yTrue, yPred, dpiarg{:} );
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
           if nargin < 4
                dpiarg = {};
            else
                dpiarg = {dpi};
            end
            [obj, performance, dpi] = ...
                  calcPerformance@PerformanceMeasures.BAC( obj, yTrue, yPred, dpiarg{:} );
            obj.bac = performance;
            performance = 1 - (((1 - obj.sensitivity)^2 + (1 - obj.specificity)^2) / 2)^0.5;
        end
        % -----------------------------------------------------------------
    
    end

end

