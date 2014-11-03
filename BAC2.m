classdef BAC2 < PerformanceMeasure
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC2( yTrue, yPred )
            obj = obj@PerformanceMeasure( yTrue, yPred );
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
            d = double( obj.performance );
        end
        % -----------------------------------------------------------------
    
        function s = char( obj )
            s = num2str( obj.performance );
        end
        % -----------------------------------------------------------------
    
        function performance = calcPerformance( obj, yTrue, yPred )
            tp = sum( yTrue == 1 & yPred >= 0 );
            tn = sum( yTrue == -1 & yPred < 0 );
            tp_fn = sum( yTrue == 1 );
            tn_fp = sum( yTrue == -1 );
            if tp_fn == 0;
                warning( 'No positive true label.' );
                sensitivity = 0;
            else
                sensitivity = tp / tp_fn;
            end
            if tn_fp == 0;
                warning( 'No negative true label.' );
                specificity = 0;
            else
                specificity = tn / tn_fp;
            end
            performance = 1 - (((1 - sensitivity)^2 + (1 - specificity)^2) / 2)^0.5;
        end
        % -----------------------------------------------------------------

    end

end

