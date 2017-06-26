classdef STLTrainerDecorator < ModelTrainers.Base & Parameterized
    % STLTrainerDecorator enhances supervised trainer with STL 
    %   This trainer enhances a supervised trainer with STL 
    %   (self-taught learning). The supervised trainer, a sparse base 
    %   and a sparsity factor beta are given as input. 
    %   The implementation will optimize the pipeline features wrt a 
    %   sparse coding objective, the given beta and the given base. 
    %   The resulting activations are then used as new features for 
    %   training and testing with the wrapped trainer.
    %% --------------------------------------------------------------------
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        trainer;
        scalingModel;
        beta;
        base;       
    end

    %% --------------------------------------------------------------------
    methods

        function obj = STLTrainerDecorator( varargin )
            pds{1} = struct( 'name', 'trainer', ...
                             'default', @ModelTrainers.GlmNetLambdaSelect, ...
                             'valFun', @(x)(isa(x, @ModelTrainers.Base)) );
            pds{2} = struct( 'name', 'scalingModel', ...
                             'default', -1, ...
                             'valFun', @(x)(isa(x, @Models.SparseCodingModel)) );
            pds{3} = struct( 'name', 'beta', ...
                             'default', 0.6, ...
                             'valFun', @(x)(isnumeric(x) && numel(x) == 1) );
            pds{4} = struct( 'name', 'base', ...
                             'default', -1, ...
                             'valFun', @(x)(ismatrix(x)) );
            pds{5} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
            
            % check for necessary parts 
            if obj.scalingModel == -1
                error('You have to pass a scalingModel to STLTrainerDecorator.');
            end
            if obj.base == -1
                error('You have to pass a base to STLTrainerDecorator.');
            end
            
            % TODO call constructors of trainer to pass on arguments
            obj.trainer( varargin{:} );
            
            % TODO or this way?
            % obj.setParameters( true, ...
            %       'buildCoreTrainer', @obj.trainer, ...
            %       varargin{:} );
        end
        %% ----------------------------------------------------------------
        
        % TODO which other methods have to be overwritten?
        
        function buildModel( obj, x, y )          
            x(isnan(x)) = 0;
            x(isinf(x)) = 0;
            
            % we have to take the scale from the original base
            xScaled = obj.scalingModel.scale2zeroMeanUnitVar( x);
            clear x;
            
            % feature extraction
            % transpose B and feature vector because algorithm assumes
            % columnwise data, output is transposed as well
            features = l1ls_featuresign(obj.base', xScaled', obj.beta);
            
            % now run wrapped trainer (features have to be transposed)
            obj.trainer.buildModel(features', y);
        end
        %% ----------------------------------------------------------------
            
        function performance = getPerformance( obj, getDatapointInfo )
            performance = obj.trainer.getPerformance(getDatapointInfo);
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.trainer.giveTrainedModel;
        end
        %% ----------------------------------------------------------------
        
    end
    
end