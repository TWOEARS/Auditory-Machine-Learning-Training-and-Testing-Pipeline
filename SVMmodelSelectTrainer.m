classdef SVMmodelSelectTrainer < IdTrainerInterface
    
    %% -----------------------------------------------------------------------------------
    properties (Access = private)
        gridCVtrainer;
        svmCoreTrainer;
        parameters;
        trainWithBestHps = true;
        hpsSets;
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
            ip.addParameter( 'hpsEpsilons', 0.001, ...
                @(x)(isfloat(x) && x > 0) );
            ip.addParameter( 'hpsSearchBudget', 8, ...
                @(x)(rem(x,1) == 0 && x > 0) );
            ip.addParameter( 'hpsCrange', [-6 2], ...
                @(x)(isfloat(x) && length(x) == 2 && x(1) < x(2)) );
            ip.addParameter( 'hpsGammaRange', [-12 3], ...
                @(x)(isfloat(x) && length(x) == 2 && x(1) < x(2)) );
            ip.addParameter( 'hpsCvFolds', 4, ...
                @(x)(rem(x,1) == 0 && x > 0) );
            ip.addParameter( 'hpsMaxDataSize', 10000, ...
                @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            ip.addParameter( 'makeProbModel', false, @islogical );
            
            obj.parameters = ip.parseParameters( obj.parameters, setDefaults, varargin{:} );
            obj.setPerformanceMeasure( obj.parameters.performanceMeasure );
        end
        %% -------------------------------------------------------------------------------

        function run( obj )
            obj.svmCoreTrainer = SVMtrainer();
            obj.createHpsTrainer();
            hps.params = obj.determineHyperparameterSets();
            hps.perfs = zeros( size( hps.params ) );
            verboseFprintf( obj, '\nHyperparameter search CV...\n' );
            for ii = 1 : size( hps.params, 1 )
                verboseFprintf( obj, '\nhps set %d...\n ', ii );
                obj.svmCoreTrainer.setParameters( false, ...
                    'maxDataSize', obj.parameters.hpsMaxDataSize, ...
                    'makeProbModel', false, ...
                    hps.params(ii) );
                obj.gridCVtrainer.abortPerfMin = max( hps.perfs );
                obj.gridCVtrainer.run();
                hps.perfs(ii) = obj.gridCVtrainer.getPerformance().avg;
            end
            verboseFprintf( obj, 'Done\n' );
            if obj.parameters.hpsRefineStages > 0
                verboseFprintf( obj, 'HPS refine stage...\n' );
                refineGridTrainer = obj.createRefineGridTrainer( hps );
                refineGridTrainer.run();
                hps.params = [hps.params; refineGridTrainer.hpsSets.params];
                hps.perfs = [hps.perfs; refineGridTrainer.hpsSets.perfs];
            end
            obj.hpsSets = obj.sortHpsSetsByPerformance( hps );
            verboseFprintf( obj, 'Best HPS set performance: %f\n', obj.hpsSets.perfs(end) );
            if obj.trainWithBestHps
                obj.svmCoreTrainer.setParameters( false, ...
                    obj.hpsSets.params(end), ...
                    'makeProbModel', obj.parameters.makeProbModel, ...
                    'maxDataSize', inf );
                obj.svmCoreTrainer.setData( obj.trainSet, obj.testSet );
                verboseFprintf( obj, 'Train with best HPS set on full trainSet...\n' );
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
        
        function createHpsTrainer( obj )
            obj.gridCVtrainer = CVtrainer( obj.svmCoreTrainer );
            obj.gridCVtrainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.gridCVtrainer.setPositiveClass( obj.positiveClass );
            obj.gridCVtrainer.setData( obj.trainSet, obj.testSet );
            obj.gridCVtrainer.setNumberOfFolds( obj.parameters.hpsCvFolds );
        end
        %% -------------------------------------------------------------------------------
        
        function hpsSets = determineHyperparameterSets( obj )
            switch( lower( obj.parameters.hpsMethod ) )
                case 'grid'
                    hpsSets = obj.getHpsGridSearchSets();
                case 'random'
                    error( 'not implemented' );
                case 'intelligrid'
                    error( 'not implemented.' );
            end
        end
        %% -------------------------------------------------------------------------------

        function hpsSets = getHpsGridSearchSets( obj )
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
            hpsSets = cell2struct( num2cell(hpsSets), {'kernel','epsilon','c','gamma'},2 );
        end
        %% -------------------------------------------------------------------------------
        
        function refineGridTrainer = createRefineGridTrainer( obj, hps )
            refineGridTrainer = SVMmodelSelectTrainer( obj.parameters );
            refineGridTrainer.setPositiveClass( obj.positiveClass );
            refineGridTrainer.setData( obj.trainSet, obj.testSet );
            refineGridTrainer.trainWithBestHps = false;
            hps = obj.sortHpsSetsByPerformance( hps );
            best3LogMean = @(fn)(mean( log10( [hps.params(end-2:end).(fn)] ) ));
            eRefinedRange = getNewLogRange( ...
                log10(obj.parameters.hpsEpsilons), best3LogMean('epsilon') );
            cRefinedRange = getNewLogRange( ...
                obj.parameters.hpsCrange, best3LogMean('c') );
            gRefinedRange = getNewLogRange( ...
                obj.parameters.hpsGammaRange, best3LogMean('gamma') );
            refineGridTrainer.setParameters( false, ...
                'hpsRefineStages', obj.parameters.hpsRefineStages - 1, ...
                'hpsGammaRange', gRefinedRange, ...
                'hpsCrange', cRefinedRange, ...
                'hpsEpsilons', unique( 10.^[eRefinedRange, best3LogMean('epsilon')] ) );
        end
        %% -------------------------------------------------------------------------------
        
        function hps = sortHpsSetsByPerformance( obj, hps )
            [hps.perfs,idx] = sort( hps.perfs );
            hps.params = hps.params(idx);
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end