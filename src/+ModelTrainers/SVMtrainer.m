classdef SVMtrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        epsilon;
        kernel;
        c;
        gamma;
        makeProbModel;
        usePca;
        pcaVarThres;
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

        function obj = SVMtrainer( varargin )
            pds{1} = struct( 'name', 'epsilon', ...
                             'default', 0.001, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{2} = struct( 'name', 'kernel', ...
                             'default', 0, ...
                             'valFun', @(x)(rem(x,1) == 0 && all(x == 0 | x == 2)) );
            pds{3} = struct( 'name', 'c', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{4} = struct( 'name', 'gamma', ...
                             'default', 0.1, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{5} = struct( 'name', 'makeProbModel', ...
                             'default', false, ...
                             'valFun', @islogical );
            pds{6} = struct( 'name', 'usePca', ...
                             'default', false, ...
                             'valFun', @islogical );
            pds{7} = struct( 'name', 'pcaVarThres', ...
                             'default', 0.99, ...
                             'valFun', @(x)(isfloat(x) && x > 0 && x <= 1) );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.Base( varargin{:} );
            obj.setParameters( true, varargin{:} );
            obj.model = Models.SVMmodel.empty;
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y, iw )
            if ~all( iw )
                warning( 'AMLTTP:usage:unsupported', ...
                         ['SVmtrainer can''t use individual sample importance weights '...
                          'produced bei ImportanceWeighter. '...
                          'Instead, class-wide weights will be used.'] );
            end
            [x, y, cp] = obj.prepareData( x, y );
            if obj.usePca
                obj.model = Models.SvmPcaModel( obj.pcaVarThres );
            else
                obj.model = Models.SVMmodel();
            end
            obj.model.useProbModel = obj.makeProbModel;
            x = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            if obj.usePca
                fprintf( '\nPCA dim reduction from %d features...\n', size( x, 2 ) );
                x = obj.model.reduceToPCs( x, true );
                fprintf( '\n...dim PCA-reduced to %d features.\n', size( x, 2 ) );
            end
            m = ceil( numel(  x  ) * 8 / (1024 * 1000) );
            m = min( 2*m, 2000 );
            svmParamStrScheme = '-t %d -g %e -c %e -w-1 1 -w1 %e -e %e -m %d -b %d -h 0';
            svmParamStr = sprintf( svmParamStrScheme, ...
                obj.kernel, obj.gamma, ...
                obj.c, cp, ...
                obj.epsilon, m, obj.makeProbModel );
            if ~obj.verbose, svmParamStr = [svmParamStr, ' -q']; end
            fprintf( ['\nSVM training with param string\n\t%s\n' ...
                                  '\tsize(x) = %dx%d\n'], svmParamStr, size(x,1), size(x,2) );
            obj.model.model = libsvmtrain( double( y ), double( x ), svmParamStr );
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.model;
        end
        %% ----------------------------------------------------------------
        
        function [x,y,cp] = prepareData( obj, x, y )
            ypShare = ( mean( y ) + 1 ) * 0.5;
            cp = ( 1 - ypShare ) / ypShare;
            if isnan( cp ) || isinf( cp )
                warning( 'The share of positive to negative examples is inf or nan.' );
            end
            if obj.makeProbModel
                x = [x(y == -1,:); repmat( x(y == +1,:), round( cp ), 1)];
                y = [y(y == -1); repmat( y(y == +1), round( cp ), 1)];
                cp = 1;
            end
        end
        %% ----------------------------------------------------------------
        
    end
    
end