classdef SparseCodingModel < Models.DataScalingModel
    
    
    %% --------------------------------------------------------------------
    properties
        % assumes row wise data points, bases and coefficients 
        beta;   % sparsity factor
        B;      % base for sparse coding
        S; % coefficients for base B
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = SparseCodingModel()
            % TODO init model?
        end
        %% -----------------------------------------------------------------

        function setBeta( obj, newBeta)
            obj.beta = newBeta;
        end
        %% -----------------------------------------------------------------
        
        function setB( obj, newB)
            obj.B = newB;
        end
        %% -----------------------------------------------------------------
        
        function setS( obj, newS)
            obj.S = newS;
        end
        %% -----------------------------------------------------------------
    
    end
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            % eval optimization objective here without optimizing. 
            % y is set to -1, since we use unlabeled data
            diff = x - obj.S * obj.B;
            l2_diff   = sqrt( sum( abs(diff).^2, 2 ) );
            l1_sparse = sum(sum(abs(obj.S))); 
            
            score = sum( l2_diff) + obj.beta * l1_sparse; 
            y = -1 * ones(size(x, 1), 1);
        end
        %% -----------------------------------------------------------------

    end
    
     methods (Static)
        
        function objVal = eval( B, S, X, beta )
            diff = X - S * B;
            l2_diff   = sqrt( sum( abs(diff).^2, 2 ) );
            l1_sparse = sum(sum(abs(S))); 
            
            objVal = sum( l2_diff) + beta * l1_sparse; 
        end
        %% -----------------------------------------------------------------

    end
    
end
