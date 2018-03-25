classdef LoadModelNoopTrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = LoadModelNoopTrainer( modelPath, varargin )
            pds{1} = struct( 'name', 'modelParams', ...
                             'default', struct(), ...
                             'valFun', @(x)(isstruct( x )) );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.Base( varargin{:} );
            obj.setParameters( true, varargin{:} );
            if ~exist( modelPath, 'file' )
                error( 'Could not find "%s".', modelPath );
            end
            ms = load( modelPath, 'model' );
            model = ms.model;
            fieldsModelParams = fieldnames( modelParams );
            for ii = 1: length( fieldsModelParams )
                model.(fieldsModelParams{ii}) = modelParams.(fieldsModelParams{ii});
            end
            obj.model = model;
        end
        %% ----------------------------------------------------------------

        function buildModel( ~, ~, ~, ~ )
            % noop
        end
        %% ----------------------------------------------------------------
        
        % override of ModelTrainers.Base
        function model = getModel( obj )
            model = obj.giveTrainedModel();
            if ~isa( model, 'Models.Base' )
                error( 'giveTrainedModel must produce an Models.Base object.' );
            end
            if ~isempty( ModelTrainers.Base.featureMask )
                assert( isequal( model.featureMask, ModelTrainers.Base.featureMask ) );
            else
                ModelTrainers.Base.featureMask( true, model.featureMask );
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.model;
        end
        %% ----------------------------------------------------------------
        
    end
    
end