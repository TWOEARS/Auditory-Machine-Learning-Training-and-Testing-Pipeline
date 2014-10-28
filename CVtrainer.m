classdef CVtrainer < IdTrainerInterface

    % ---------------------------------------------------------------------
    properties (SetAccess = protected)
        trainer;
    end
    
    % ---------------------------------------------------------------------
    methods

        function obj = CVtrainer( trainer )
            if ~isa( trainer, 'IdTrainerInterface' )
                error( 'trainer must implement IdTrainerInterface' );
            end
            obj.trainer = trainer;
        end
        % -----------------------------------------------------------------
        
        function setPositiveClass( obj, modelName )
        end
        % -----------------------------------------------------------------
        
        function run( obj )
        end
        % -----------------------------------------------------------------
        
        function performance = getPerformance( obj )
        end
        % -----------------------------------------------------------------
        
        function model = getModel( obj )
        end
        % -----------------------------------------------------------------
        
    end
    
end