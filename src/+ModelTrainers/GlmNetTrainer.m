classdef GlmNetTrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        alpha;
        family;
        nLambda;
        lambda;
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)

        function cpObj = copyElement( obj )
            cpObj = copyElement@ModelTrainers.Base( obj );
            cpObj.model = copy( obj.model );
        end
        %% ----------------------------------------------------------------
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = GlmNetTrainer( varargin )
            pds{1} = struct( 'name', 'alpha', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x >= 0 && x <= 1.0) );
            pds{2} = struct( 'name', 'family', ...
                             'default', 'binomial', ...
                             'valFun', @(x)(ischar(x) && any(strcmpi(x, ...
                                                                     {'binomial',...
                                                                      'multinomial',...
                                                                      'multinomialGrouped',...
                                                                      'gaussian',...
                                                                      'poisson'}))) );
            pds{3} = struct( 'name', 'nLambda', ...
                             'default', 100, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{4} = struct( 'name', 'lambda', ...
                             'default', [], ...
                             'valFun', @(x)(isempty(x) || isfloat(x)) );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.Base( varargin{:} );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y, iw )
            glmOpts.weights = iw(:);
            obj.model = Models.GlmNetModel();
            x(isnan(x)) = 0;
            x(isinf(x)) = 0;
            x = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            glmOpts.alpha = obj.alpha;
            glmOpts.nlambda = obj.nLambda;
            if ~isempty( obj.lambda )
                glmOpts.lambda = obj.lambda;
            end
            if strcmpi( obj.family, 'multinomialGrouped' )
                family = 'multinomial'; %#ok<*PROPLC>
                glmOpts.mtype = 'grouped';
            else
                family = obj.family;
            end
            fprintf( '\nGlmNet training with alpha=%f\n\tsize(x) = %dx%d\n\n', ...
                                        glmOpts.alpha, size(x,1), size(x,2) );
            obj.model.model = glmnet( double( x ), double( y ), family, glmOpts );
            obj.model.trainedWithAlpha = obj.alpha;
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.model;
        end
        %% ----------------------------------------------------------------
        
    end
    
end