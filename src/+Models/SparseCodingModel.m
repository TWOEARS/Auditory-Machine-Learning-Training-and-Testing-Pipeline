classdef SparseCodingModel < Models.DataScalingModel
    
    
    %% --------------------------------------------------------------------
    properties
        B;      % row-wise base for sparse coding
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = SparseCodingModel()
        end
        %% -----------------------------------------------------------------
        
        function setB( obj, newB)
            obj.B = newB;
        end
        %% -----------------------------------------------------------------
            
    end
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            % the model is unsupervised and just stores the base
            score = 0;
            y = -1;
        end
        %% -----------------------------------------------------------------

    end
    
end
