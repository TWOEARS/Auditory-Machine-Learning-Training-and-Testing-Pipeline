classdef SVMtrainer < IdTrainerInterface
    
    %% --------------------------------------------------------------------
    properties (Access = public)
        kernel;
        epsilon;
        c;
        gamma;
        makeProbModel;
        model;
        performanceMeasure;
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

        function set.performanceMeasure( obj, newPerformanceMeasure )
            if ~isa( newPerformanceMeasure, 'PerformanceMeasure' )
                error( 'newPerformanceMeasure must implement PerformanceMeasure interface.' );
            end
            obj.performanceMeasure = newPerformanceMeasure;
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
                cp = 1 / obj.getPosToNegRatio();
            end
            datPermutation = randperm( length( y ) );
            x = x(datPermutation);
            y = y(datPermutation);
            obj.model = SVMmodel();
            obj.model.useProbModel = obj.makeProbModel;
            saveScalingFactors = true;
            xScaled = obj.model.scale2zeroMeanUnitVar( x, saveScalingFactors );
            svmParamStrScheme = '-t %d -g %e -c %e -w-1 1 -w1 %e -q -e %e -m 500 -h 1 -b %d';
            svmParamStr = sprintf( svmParamStrScheme, ...
                obj.kernel, obj.gamma, obj.c, cp, obj.epsilon, obj.makeProbModel );
            obj.model.model = libsvmtrain( y, xScaled, svmParamStr );
        end
        %% ----------------------------------------------------------------
        
        function performance = getPerformance( obj )
            x = obj.testSet(:,:,'x');
            y = obj.testSet(:,:,'y',obj.positiveClass);
            yModel = obj.model.applyModel( x );
            performance = obj.performanceMeasure.calcPerformance( y, yModel );
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
            x = [x(y == -1,:); repmat( x(y == +1,:), floor(posNegRatio), 1)];
            y = [y(y == -1); repmat( y(y == +1), floor(posNegRatio), 1)];
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end