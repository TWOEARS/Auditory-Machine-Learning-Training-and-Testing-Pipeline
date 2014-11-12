classdef SVMtrainer < IdTrainerInterface & Parameterized
    
    %% --------------------------------------------------------------------
    properties (Access = protected)
        model;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = SVMtrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'epsilon', ...
                             'default', 0.001, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{3} = struct( 'name', 'kernel', ...
                             'default', 0, ...
                             'valFun', @(x)(rem(x,1) == 0 && all(x == 0 | x == 2)) );
            pds{4} = struct( 'name', 'c', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{5} = struct( 'name', 'gamma', ...
                             'default', 0.1, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{6} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{7} = struct( 'name', 'makeProbModel', ...
                             'default', false, ...
                             'valFun', @islogical );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            if obj.parameters.makeProbModel
                [x,y] = obj.bloat2balancedData( obj.trainSet );
                cp = 1;
            else
                x = obj.trainSet(:,:,'x');
                y = obj.trainSet(:,:,'y',obj.positiveClass);
                cp = 1 / obj.getPosToNegRatio( obj.trainSet );
                if isnan( cp ) || isinf( cp )
                    warning( 'The share of positive to negative examples is inf or nan.' );
                end
            end
            if isempty( x ), error( 'There is no data to train the model.' ); end
            datPermutation = randperm( length( y ) );
            x = x(datPermutation,:);
            y = y(datPermutation);
            if length( y ) > obj.parameters.maxDataSize
                x(obj.parameters.maxDataSize+1:end,:) = [];
                y(obj.parameters.maxDataSize+1:end) = [];
            end
            obj.model = SVMmodel();
            obj.model.useProbModel = obj.parameters.makeProbModel;
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            svmParamStrScheme = '-t %d -g %e -c %e -w-1 1 -w1 %e -e %e -m 500 -b %d -h 0';
            svmParamStr = sprintf( svmParamStrScheme, ...
                obj.parameters.kernel, obj.parameters.gamma, ...
                obj.parameters.c, cp, ...
                obj.parameters.epsilon, obj.parameters.makeProbModel );
            if ~obj.verbose, svmParamStr = [svmParamStr, ' -q']; end
            verboseFprintf( obj, 'SVM training with param string\n\t%s\n', svmParamStr );
            verboseFprintf( obj, '\tsize(x) = %dx%d\n', size(x,1), size(x,2) );
            obj.model.model = libsvmtrain( y, xScaled, svmParamStr );
            verboseFprintf( obj, '\n' );
        end
        %% ----------------------------------------------------------------
        
        function performance = getPerformance( obj )
            if isempty( obj.testSet ), error( 'There is no testset to test on.' ); end
            x = obj.testSet(:,:,'x');
            y = obj.testSet(:,:,'y',obj.positiveClass);
            if isempty( x ), error( 'There is no data to test the model.' ); end
            verboseFprintf( obj, 'SVM testing...\n' );
            yModel = obj.model.applyModel( x );
            performance = obj.performanceMeasure( y, yModel );
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
    
    %% --------------------------------------------------------------------
    methods (Access = private)

        function posNegRatio = getPosToNegRatio( obj, dataSet )
            ypShare = ( mean( dataSet(:,:,'y',obj.positiveClass) ) + 1 ) * 0.5;
            posNegRatio = ypShare/(1-ypShare);
        end
        %% -------------------------------------------------------------------------------

        function [x,y] = bloat2balancedData( obj, dataSet )
            posNegRatio = obj.getPosToNegRatio( dataSet );
            x = dataSet(:,:,'x');
            y = dataSet(:,:,'y',obj.positiveClass);
            x = [x(y == -1,:); repmat( x(y == +1,:), round(1/posNegRatio), 1)];
            y = [y(y == -1); repmat( y(y == +1), round(1/posNegRatio), 1)];
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end