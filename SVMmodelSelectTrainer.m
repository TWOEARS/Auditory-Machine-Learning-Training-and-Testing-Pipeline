classdef SVMmodelSelectTrainer < IdTrainerInterface
    
    %% -----------------------------------------------------------------------------------
    properties (Access = private)
        gridCVtrainer;
        svmCoreTrainer;
        parameters;
        hpsSets;
        trainWithBestHps = true;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (Access = public)
    end

    %% -----------------------------------------------------------------------------------
    methods

        function obj = SVMmodelSelectTrainer( varargin )
            obj.setParameters( true, varargin{:} );
        end
        %% -------------------------------------------------------------------------------

        function setParameters( obj, setDefaults, varargin )
            ip = ExtendedInputParser();
            ip.addParameter( 'performanceMeasure', @BAC2, @(x)(isa( x, 'function_handle' )) );
            ip.addParameter( 'hpsRefineStages', 1, ...
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
            
            obj.parameters = ip.parseParameters( obj.parameters, setDefaults, varargin{:} );
            obj.setPerformanceMeasure( obj.parameters.performanceMeasure );
        end
        %% -------------------------------------------------------------------------------

        function run( obj )
            obj.setupHpsTrainer();
            obj.hpsSets = obj.determineHyperparameterSets();
            verboseFprintf( obj, '\nHyperparameter search CV...\n' );
            bestHpsPerf = 0;
            for ii = 1 : size( obj.hpsSets, 1 )
                verboseFprintf( obj, '\nhps set %d...\n ', ii );
                obj.svmCoreTrainer.kernel = obj.hpsSets(ii,1);
                obj.svmCoreTrainer.epsilon = obj.hpsSets(ii,2);
                obj.svmCoreTrainer.c = obj.hpsSets(ii,3);
                obj.svmCoreTrainer.gamma = obj.hpsSets(ii,4);
                obj.svmCoreTrainer.makeProbModel = false;
                obj.gridCVtrainer.abortPerfMin = bestHpsPerf;
                obj.gridCVtrainer.run();
                hpsSetCvPerf = obj.gridCVtrainer.getPerformance();
                obj.hpsSets(ii, 5) = hpsSetCvPerf.avg;
                bestHpsPerf = max( hpsSetCvPerf.avg, bestHpsPerf );
            end
            verboseFprintf( obj, 'Done\n' );
            if obj.parameters.hpsRefineStages > 0
                verboseFprintf( obj, 'HPS refine stage...\n' );
                refineGridTrainer = obj.setupRefineGridTrainer();
                refineGridTrainer.run();
                obj.hpsSets = [obj.hpsSets; refineGridTrainer.hpsSets];
            end
            obj.hpsSets = sortrows( obj.hpsSets, 5 );
            predGenVal = obj.hpsSets(end,5);
            verboseFprintf( obj, 'Best HPS set performance: %f\n', predGenVal );
            if obj.trainWithBestHps
                obj.svmCoreTrainer.kernel = obj.hpsSets(end,1);
                obj.svmCoreTrainer.epsilon = obj.hpsSets(end,2);
                obj.svmCoreTrainer.c = obj.hpsSets(end,3);
                obj.svmCoreTrainer.gamma = obj.hpsSets(end,4);
                obj.svmCoreTrainer.makeProbModel = obj.parameters.makeProbModel;
                obj.svmCoreTrainer.setData( obj.trainSet, obj.testSet );
                obj.svmCoreTrainer.maxDataSize = inf;
                verboseFprintf( obj, 'Train with best HPS set on all folds...\n' );
                obj.svmCoreTrainer.run();
            end
        end
        %% -------------------------------------------------------------------------------
        
        function performance = getPerformance( obj )
            performance = obj.svmCoreTrainer.getPerformance();
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.svmCoreTrainer.getModel();
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
        function setupHpsTrainer( obj )
            obj.svmCoreTrainer = SVMtrainer();
            obj.svmCoreTrainer.verbose = obj.verbose;
            obj.svmCoreTrainer.maxDataSize = obj.parameters.hpsMaxDataSize;
            obj.gridCVtrainer = CVtrainer( obj.svmCoreTrainer );
            obj.gridCVtrainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.gridCVtrainer.setPositiveClass( obj.positiveClass );
            obj.gridCVtrainer.setData( obj.trainSet, obj.testSet );
            obj.gridCVtrainer.setNumberOfFolds( obj.parameters.hpsCvFolds );
            obj.gridCVtrainer.verbose = obj.verbose;
        end
        %% -------------------------------------------------------------------------------
        
        function hpsSets = determineHyperparameterSets( obj )
            switch( lower( obj.parameters.hpsMethod ) )
                case 'grid'
                    hpsSets = obj.hpsGridSearchSets();
                case 'random'
                    error( 'not implemented' );
                    for i = 1 : obj.parameters.hpsSearchBudget
                        c = 10^( log10(obj.parameters.hpsCrange(1)) + ( log10(obj.parameters.hpsCrange(2)) - log10(obj.parameters.hpsCrange(1)) ) * rand() );
                        g = 10^( log10(obj.parameters.hpsGammaRange(1)) + ( log10(obj.parameters.hpsGammaRange(2)) - log10(obj.parameters.hpsGammaRange(1)) ) * rand() );
                    end
                case 'intelligrid'
                    error( 'not implemented.' );
            end
        end
        %% -------------------------------------------------------------------------------

        function hpsSets = hpsGridSearchSets( obj )
            hpsCs = logspace( obj.parameters.hpsCrange(1), ...
                              obj.parameters.hpsCrange(2), ...
                              obj.parameters.hpsSearchBudget );
            hpsGs = logspace( obj.parameters.hpsGammaRange(1), ...
                              obj.parameters.hpsGammaRange(2), ...
                              obj.parameters.hpsSearchBudget );
            [kGrid, eGrid, cGrid, gGrid] = ndgrid( ...
                                                obj.parameters.hpsKernels, ...
                                                obj.parameters.hpsEpsilons, ...
                                                hpsCs, ...
                                                hpsGs );
            hpsSets = [kGrid(:), eGrid(:), cGrid(:), gGrid(:)];
            hpsSets(hpsSets(:,1)~=2,4) = 1; %set gamma equal for kernels other than rbf
            hpsSets = unique( hpsSets, 'rows' );
        end
        %% -------------------------------------------------------------------------------
        
        function refineGridTrainer = setupRefineGridTrainer( obj )
            refineGridTrainer = SVMmodelSelectTrainer( obj.parameters );
            refineGridTrainer.verbose = obj.verbose;
            refineGridTrainer.setPositiveClass( obj.positiveClass );
            refineGridTrainer.setData( obj.trainSet, obj.testSet );
            refineGridTrainer.trainWithBestHps = false;
            sortedHPs = sortrows( obj.hpsSets, 5 );
            best3HPsmean = mean( log10( sortedHPs(end-2:end,:) ), 1 );
            eRefinedRange = getNewLogRange( log10(obj.parameters.hpsEpsilons), best3HPsmean(2) );
            cRefinedRange = getNewLogRange( obj.parameters.hpsCrange, best3HPsmean(3) );
            gRefinedRange = getNewLogRange( obj.parameters.hpsGammaRange, best3HPsmean(4) );
            refineGridTrainer.setParameters( false, ...
                'hpsRefineStages', obj.parameters.hpsRefineStages - 1, ...
                'hpsGammaRange', gRefinedRange, ...
                'hpsCrange', cRefinedRange, ...
                'hpsEpsilons', unique( 10.^[eRefinedRange, best3HPsmean(2)] ) );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end