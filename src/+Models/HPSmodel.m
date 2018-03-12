classdef HPSmodel < Models.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = ?ModelTrainers.HpsTrainer)
        hpsSet;
        model;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = HPSmodel()
        end
        %% -----------------------------------------------------------------
        
        % override of Models.Base
        function [y,score] = applyModel( obj, x )
            if ~isempty( obj.model.featureMask ) && isempty( obj.featureMask )
                obj.featureMask = obj.model.featureMask;
            end
            [y,score] = applyModel@Models.Base( obj, x );
        end
        %% -------------------------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function [y,score] = applyModelMasked( obj, x )
            [y,score] = obj.model.applyModelMasked( x );
        end
        %% -----------------------------------------------------------------

    end
    
end

