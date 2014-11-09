classdef SVMtrainer < IdTrainerInterface
    
    %% --------------------------------------------------------------------
    properties (Access = public)
        kernel;
        epsilon;
        c;
        gamma;
        makeProbModel;
        model;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = SVMtrainer( )
            obj.makeProbModel = false;
        end
        %% ----------------------------------------------------------------

        function set.kernel( obj, newKernel )
            if ~any( newKernel == [0, 2] )
                error( 'Kernel not supported. Must be 0 (linear) or 2 (rbf)' );
            end
            obj.kernel = newKernel;
        end
        %% ----------------------------------------------------------------

        function set.makeProbModel( obj, newMakeProbModel )
            if ~isa( newMakeProbModel, 'logical' )
                error( 'makeProbModel must be a logical value.' );
            end
            obj.makeProbModel = newMakeProbModel;
        end
        %% ----------------------------------------------------------------

        function run( obj )
            if obj.makeProbModel
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
            obj.model = SVMmodel();
            obj.model.useProbModel = obj.makeProbModel;
            saveScalingFactors = true;
            xScaled = obj.model.scale2zeroMeanUnitVar( x, saveScalingFactors );
            svmParamStrScheme = '-t %d -g %e -c %e -w-1 1 -w1 %e -e %e -m 500 -h 1 -b %d';
            svmParamStr = sprintf( svmParamStrScheme, ...
                obj.kernel, obj.gamma, obj.c, cp, obj.epsilon, obj.makeProbModel );
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