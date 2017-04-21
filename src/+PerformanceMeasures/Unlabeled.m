classdef Unlabeled < PerformanceMeasures.Base
    % Unlabeled performanceMeasure for an unlabeled training method
    %   Is just a wrapper class that stores an objective value, which is
    %   passed on as performance to fit into the pipeline. The logic of
    %   calculating the objective value has to be done in the trainer. 
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        objVal;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = Unlabeled(objVal, yTrue, yPred, datapointInfo )
            if nargin < 3 
                error( 'Not enough input arguments' );
            end
            if nargin < 4
                dpiarg = {};
            else
                dpiarg = {datapointInfo};
            end
            obj = obj@PerformanceMeasures.Base( yTrue, yPred, dpiarg{:} );
            
            obj.objVal = objVal;
            % normalize objective value
            if objVal < 1
                obj.performance = 1;
            else
                % use log to reduce objVal and thus prevent numerical 
                % issues for big numbers TODO good enough?
                obj.performance = 1 / log(objVal);
            end
            %TODO can datapointInfo be ignored?
            
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
            % has to be implemented, since abstract in superclass, but has
            % no use yet 
            performance = obj.performance;
            if nargin < 4
                dpi = struct.empty;
            else
                dpi.yTrue = yTrue;
                dpi.yPred = yPred;
            end 
        end
        
    end

end

