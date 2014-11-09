classdef SVMmodelSelectTrainer < IdTrainerInterface
    
    %% ---------------------------------------------------------------------
    properties (Access = private)
        gridCVtrainer;
        svmCoreTrainer;
        hyperParamSearch;
        hpsSets;
        makeProbModel;
    end
    
    %% ---------------------------------------------------------------------
    properties (Access = public)
    end

    %% ---------------------------------------------------------------------
    methods

        function obj = SVMmodelSelectTrainer( performanceMeasure, varargin )
            ip = inputParser();
            ip.addRequired( 'performanceMeasure', @(x)(isa( x, 'function_handle' )) );
            ip.addParameter( 'hpsRefineStages', 0, ...
                @(x)(rem(x,1) == 0 && x >= 0) );
            ip.addParameter( 'hpsMethod', 'grid', ...
                @(x)(ischar(x) && any(strcmpi(x, {'grid','random'}))) );
            ip.addParameter( 'hpsKernels', 0, ...
                @(x)(rem(x,1) == 0 && all(x == 0 | x == 2)) );
            ip.addParameter( 'hpsEpsilons', 0.05, ...
                @(x)(isfloat(x) && x > 0) );
            ip.addParameter( 'hpsSearchBudget', 8, ...
                @(x)(rem(x,1) == 0 && x > 0) );
            ip.addParameter( 'hpsCrange', [-5 2], ...
                @(x)(isfloat(x) && length(x) == 2 && x(1) < x(2)) );
            ip.addParameter( 'hpsGammaRange', [-12 3], ...
                @(x)(isfloat(x) && length(x) == 2 && x(1) < x(2)) );
            ip.addParameter( 'hpsCvFolds', 4, ...
                @(x)(rem(x,1) == 0 && x > 0) );
            ip.addParameter( 'hpsMaxDataSize', 10000, ...
                @(x)(rem(x,1) == 0 && x > 0) );
            ip.addParameter( 'makeProbModel', false, @islogical );
            ip.parse( performanceMeasure, varargin{:} );
            
            obj.svmCoreTrainer = SVMtrainer();
            obj.gridCVtrainer = CVtrainer( obj.svmCoreTrainer );

            obj.makeProbModel = ip.Results.makeProbModel;
            obj.hyperParamSearch.refineStages = ip.Results.hpsRefineStages;
            obj.hyperParamSearch.method = ip.Results.hpsMethod;
            obj.hyperParamSearch.kernels = ip.Results.hpsKernels;
            obj.hyperParamSearch.epsilons = ip.Results.hpsEpsilons;
            obj.hyperParamSearch.searchBudget = ip.Results.hpsSearchBudget;
            obj.hyperParamSearch.cRange = ip.Results.hpsCrange;
            obj.hyperParamSearch.gammaRange = ip.Results.hpsGammaRange;
            obj.hyperParamSearch.maxDataSize = ip.Results.hpsMaxDataSize;
            obj.setHyperParamSearchFolds( ip.Results.hpsCvFolds );
            obj.setPerformanceMeasure( ip.Results.performanceMeasure );
        end
        %% -----------------------------------------------------------------
        
        function setPositiveClass( obj, modelName )
            setPositiveClass@IdTrainerInterface( obj, modelName );
            obj.gridCVtrainer.setPositiveClass( modelName );
            obj.svmCoreTrainer.setPositiveClass( modelName );
        end
        %% -----------------------------------------------------------------
        
        function setData( obj, trainSet, testSet )
            setData@IdTrainerInterface( obj, trainSet, testSet );
            obj.gridCVtrainer.setData( trainSet, testSet );
            obj.svmCoreTrainer.setData( trainSet, testSet );
        end
        %% -----------------------------------------------------------------

        function setPerformanceMeasure( obj, newPerformanceMeasure )
            setPerformanceMeasure@IdTrainerInterface( obj, newPerformanceMeasure );
            obj.gridCVtrainer.setPerformanceMeasure( newPerformanceMeasure );
            obj.svmCoreTrainer.setPerformanceMeasure( newPerformanceMeasure );
        end
        %% ----------------------------------------------------------------
        
        function setHyperParamSearchFolds( obj, nHpsFolds )
            obj.gridCVtrainer.setNumberOfFolds( nHpsFolds );
        end
        %% -----------------------------------------------------------------
        
        function setMakeProbModel( obj, newMakeProbModel )
            obj.makeProbModel = newMakeProbModel;
        end
        %% -----------------------------------------------------------------

        function run( obj )
            obj.gridCVtrainer.verbose = obj.verbose;
            obj.svmCoreTrainer.verbose = obj.verbose;
            obj.hpsSets = obj.determineHyperparameterSets();
            bestPerf = 0;
            obj.svmCoreTrainer.maxDataSize = obj.hyperParamSearch.maxDataSize;
            verboseFprintf( obj, 'Hyperparameter search CV...\n' );
            for ii = 1:size( obj.hpsSets, 1 )
                obj.svmCoreTrainer.kernel = obj.hpsSets(ii,1);
                obj.svmCoreTrainer.epsilon = obj.hpsSets(ii,2);
                obj.svmCoreTrainer.c = obj.hpsSets(ii,3);
                obj.svmCoreTrainer.gamma = obj.hpsSets(ii,4);
                obj.svmCoreTrainer.makeProbModel = false;
                obj.gridCVtrainer.abortPerfMin = bestPerf;
                verboseFprintf( obj, 'hps set %d... ', ii );
                obj.gridCVtrainer.run();
                foldPerf = obj.gridCVtrainer.getPerformance();
                obj.hpsSets(ii, 5) = foldPerf.avg;
                bestPerf = max( foldPerf.avg, bestPerf );
            end
            verboseFprintf( obj, 'Done\n' );
            if obj.hyperParamSearch.refineStages > 0
                verboseFprintf( obj, 'HPS refine stage...\n' );
                refineGridTrainer = SVMmodelSelectTrainer( ...
                    obj.performanceMeasure, ...
                    'hpsCvFolds', obj.gridCVtrainer.nFolds );
                refineGridTrainer.verbose = obj.verbose;
                refineGridTrainer.setPositiveClass( obj.positiveClass );
                refineGridTrainer.setData( obj.trainSet, obj.testSet );
                refineGridTrainer.hyperParamSearch = obj.hyperParamSearch;
                refineGridTrainer.hyperParamSearch.refineStages = obj.hyperParamSearch.refineStages - 1;
                sortedHPs = sortrows( obj.hpsSets, 5 );
                best3HPsmean = mean( log10( sortedHPs(end-2:end,:) ), 1 );
                eRefinedRange = getNewLogRange( log10(obj.hyperParamSearch.epsilons), best3HPsmean(2) );
                refineGridTrainer.hyperParamSearch.epsilons = unique( 10.^[eRefinedRange, best3HPsmean(2)] );
                cRefinedRange = getNewLogRange( obj.hyperParamSearch.cRange, best3HPsmean(3) );
                refineGridTrainer.hyperParamSearch.cRange = cRefinedRange;
                gRefinedRange = getNewLogRange( obj.hyperParamSearch.gammaRange, best3HPsmean(4) );
                refineGridTrainer.hyperParamSearch.gammaRange = gRefinedRange;
                refineGridTrainer.run();
                obj.hpsSets = [obj.hpsSets; refineGridTrainer.hpsSets];
            end
            obj.hpsSets = sortrows( obj.hpsSets, 5 );
            predGenVal = obj.hpsSets(end,5);
            verboseFprintf( obj, 'Best HPS set performance: %f\n', predGenVal );
            % train with the best hyperparameters, using all folds
            obj.svmCoreTrainer.kernel = obj.hpsSets(end,1);
            obj.svmCoreTrainer.epsilon = obj.hpsSets(end,2);
            obj.svmCoreTrainer.c = obj.hpsSets(end,3);
            obj.svmCoreTrainer.gamma = obj.hpsSets(end,4);
            obj.svmCoreTrainer.makeProbModel = obj.makeProbModel;
            obj.svmCoreTrainer.setData( obj.trainSet, obj.testSet );
            obj.svmCoreTrainer.maxDataSize = inf;
            verboseFprintf( obj, 'Train with best HPS set on all folds...\n' );
            obj.svmCoreTrainer.run();
        end
        %% -----------------------------------------------------------------
        
        function performance = getPerformance( obj )
            performance = obj.svmCoreTrainer.getPerformance();
        end
        %% -----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.svmCoreTrainer.getModel();
        end
        %% -----------------------------------------------------------------
        
    end

    %% ---------------------------------------------------------------------
    methods (Access = private)
        
        function hyperParameters = determineHyperparameterSets( obj )
            hyperParameters = [];
            switch( lower( obj.hyperParamSearch.method ) )
                case 'grid'
                    for k = obj.hyperParamSearch.kernels
                    for e = obj.hyperParamSearch.epsilons
                        if k == 0
                            d = round( obj.hyperParamSearch.searchBudget / length( obj.hyperParamSearch.epsilons ) );
                            for c = logspace( obj.hyperParamSearch.cRange(1), obj.hyperParamSearch.cRange(2), d );
                                hyperParameters = [hyperParameters; 0, e, c, 0];
                            end
                        end
                        if k == 2
                            d = round( ( obj.hyperParamSearch.searchBudget / length( obj.hyperParamSearch.epsilons ) ) ^ 0.5 );
                            for c = logspace( obj.hyperParamSearch.cRange(1), obj.hyperParamSearch.cRange(2), d );
                            for g = logspace( obj.hyperParamSearch.gammaRange(1), obj.hyperParamSearch.gammaRange(2), d );
                                hyperParameters = [hyperParameters; 2, e, c, g];
                            end
                            end
                        end
                    end
                    end
                case 'random'
                    for i = 1:obj.hyperParamSearch.searchBudget
                        c = 10^( log10(obj.hyperParamSearch.cRange(1)) + ( log10(obj.hyperParamSearch.cRange(2)) - log10(obj.hyperParamSearch.cRange(1)) ) * rand( 'double' ) );
                        g = 10^( log10(obj.hyperParamSearch.gammaRange(1)) + ( log10(obj.hyperParamSearch.gammaRange(2)) - log10(obj.hyperParamSearch.gammaRange(1)) ) * rand( 'double' ) );
                    end
                case 'intelligrid'
            end
        end
        %% -----------------------------------------------------------------
        
    end
    
end