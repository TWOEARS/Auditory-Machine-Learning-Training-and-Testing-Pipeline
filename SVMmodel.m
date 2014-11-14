classdef SVMmodel < IdModelInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        dataTranslators;
        dataScalors;
    end
    
    %% --------------------------------------------------------------------
    properties (SetAccess = ?SVMtrainer)
        useProbModel;
        model;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = SVMmodel()
            obj.dataTranslators = 0;
            obj.dataScalors = 1;
        end
        %% -----------------------------------------------------------------
        
        function [y,score] = applyModel( obj, x )
            x = obj.scale2zeroMeanUnitVar( x );
            yDummy = zeros( size( x, 1 ), 1 );
            [y, ~, score] = libsvmpredict( yDummy, x, obj.model, sprintf( '-q -b %d', obj.useProbModel ) );
        end
        %% -----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function x = scale2zeroMeanUnitVar( obj, x, saveScalingFactors )
            if isempty( x ), return; end;
            if nargin > 2 && strcmp( saveScalingFactors, 'saveScalingFactors' )
                obj.dataTranslators = mean( x );
                obj.dataScalors = 1 ./ std( x );
            end
            x = x - repmat( obj.dataTranslators, size(x,1), 1 );
            x = x .* repmat( obj.dataScalors, size(x,1), 1 );
        end
        %% -----------------------------------------------------------------
        
    end
    
end

