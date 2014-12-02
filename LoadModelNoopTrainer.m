classdef LoadModelNoopTrainer < IdTrainerInterface & Parameterized
    
    %% --------------------------------------------------------------------
    properties (Access = protected)
        modelPathBuilder;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = LoadModelNoopTrainer( modelPathBuilder, varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
            obj.modelPathBuilder = modelPathBuilder;
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
            % noop
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            if ~exist( obj.modelPathBuilder( obj.positiveClass ), 'file' )
                error( 'Could not find "%s".', modelPath );
            end
            ms = load( obj.modelPathBuilder( obj.positiveClass ) );
            model = ms.model;
        end
        %% ----------------------------------------------------------------
        
    end
    
end