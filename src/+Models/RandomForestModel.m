classdef RandomForestModel < Models.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?ModelTrainers.Base,?Models.Base})
        model;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = RandomForestModel()
        end
        %% -----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
            
        function [y,score] = applyModelMasked( obj, x )
            [y,score] = predict( obj.model, x );
            y = cellfun( @str2num,  y );
        end
        %% -----------------------------------------------------------------
    end

end

