classdef (Abstract) PcaReducedModel < Models.DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        explainedVarianceThreshold;
        principalComponents;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = PcaReducedModel( expVarThres )
            if nargin < 1, expVarThres = 0.99; end
            obj.explainedVarianceThreshold = expVarThres;
        end
        %% -----------------------------------------------------------------
        
        function x = reduceToPCs( obj, x, setPCs )
            if isempty( x ), return; end;
            if nargin > 2 && setPCs
                [v,pcs] = pca( x );
                normedV = abs( v ) / sum( abs( v ) );
                cumV = cumsum( normedV );
                nPcs = find( cumV >= obj.explainedVarianceThreshold, 1 );
                obj.principalComponents = pcs(:,1:nPcs);
            end
            x = x * obj.principalComponents;
        end
        %% -----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
            
        function [y,score] = applyModelToScaledData( obj, x )
            x = obj.reduceToPCs( x );
            [y, score] = obj.applyModelToReducedData( x );
        end
        %% -----------------------------------------------------------------
    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        [y,score] = applyModelToReducedData( obj, x );
    end
    
end

