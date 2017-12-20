classdef MultinomialBAC < PerformanceMeasures.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        confusionMatrix;
        sens;
        acc;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = MultinomialBAC( yTrue, yPred, datapointInfo )
           if nargin < 3
                dpiarg = {};
            else
                dpiarg = {datapointInfo};
            end
            obj = obj@PerformanceMeasures.Base( yTrue, yPred, dpiarg{:} );
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
            labels = unique( [yTrue;yPred] );
            n_acc = 0;
            for tt = 1 : numel( labels )
                for pp = 1 : numel( labels )
                    obj.confusionMatrix(tt,pp) = ...
                                     sum( (yTrue == labels(tt)) & (yPred == labels(pp)) );
                end
                n_tt = sum( obj.confusionMatrix(tt,:) );
                if n_tt > 0
                    obj.sens(tt) = obj.confusionMatrix(tt,tt) / n_tt;
                else
                    obj.sens(tt) = nan;
                end
                n_acc = n_acc + obj.confusionMatrix(tt,tt);
            end
            if nargin < 4
                dpi = struct.empty;
            else
                dpi.yTrue = yTrue;
                dpi.yPred = yPred;
            end
            obj.acc = n_acc / sum( sum( obj.confusionMatrix ) ); 
            performance = sum( obj.sens(~isnan(obj.sens)) ) / ...
                                                      numel( obj.sens(~isnan(obj.sens)) );
        end
        % -----------------------------------------------------------------
    
    end

end

