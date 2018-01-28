classdef (Abstract) HpsTrainer < ModelTrainers.Base & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        hpsCVtrainer;
        coreTrainer;
        trainWithBestHps = true;
        hpsSets;
        buildCoreTrainer;
        hpsCoreTrainerParams;
        finalCoreTrainerParams;
        finalMaxDataSize;
        hpsMaxDataSize;
        hpsRefineStages;
        hpsSearchBudget;
        hpsCvFolds;
        hpsMethod;
        abortPerfMin = 0;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = HpsTrainer( varargin )
            pds{1} = struct( 'name', 'buildCoreTrainer', ...
                             'default', [], ...
                             'valFun', @(x)(~isempty( x ) && ...
                                            isa( x, 'function_handle' )) );
            pds{2} = struct( 'name', 'hpsCoreTrainerParams', ...
                             'default', {{}}, ...
                             'valFun', @(x)(iscell( x )) );
            pds{3} = struct( 'name', 'finalCoreTrainerParams', ...
                             'default', {{}}, ...
                             'valFun', @(x)(iscell( x )) );
            pds{4} = struct( 'name', 'hpsMaxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(all( isinf(x) | (rem(x,1) == 0 & x > 0))) );
            pds{5} = struct( 'name', 'hpsRefineStages', ...
                             'default', 0, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{6} = struct( 'name', 'hpsSearchBudget', ...
                             'default', 8, ...
                             'valFun', @(x)(all( rem(x,1) == 0 ) && all( x >= 0 )) );
            pds{7} = struct( 'name', 'hpsCvFolds', ...
                              'default', 4, ...
                              'valFun', @(x)((ischar(x) && strcmpi(x,'preFolded')) || (rem(x,1) == 0 && x >= 0)) );
            pds{8} = struct( 'name', 'hpsMethod', ...
                              'default', 'grid', ...
                              'valFun', @(x)(...
                                       ischar(x) && any(strcmpi(x, {'grid','random'}))) );
            pds{9} = struct( 'name', 'finalMaxDataSize', ...
                              'default', inf, ...
                              'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.Base( varargin{:} );
            obj.setParameters( true, varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function run( obj )
            obj.buildModel();
        end
        %% ----------------------------------------------------------------
        
        function buildModel( obj, ~, ~, ~ )
            obj.coreTrainer = obj.buildCoreTrainer();
            obj.createHpsTrainer();
            hps.params = obj.determineHyperparameterSets();
            hps.perfs = zeros( size( hps.params ) );
            verboseFprintf( obj, '\nHyperparameter search CV...\n===========================\n' );
            for ii = 1 : size( hps.params, 1 )
                verboseFprintf( obj, '\nhps set %d...\n ', ii );
                obj.coreTrainer.setParameters( false, ...
                    'maxDataSize', obj.hpsMaxDataSize(1), ...
                    'maxTestDataSize', obj.maxTestDataSize, ...
                    hps.params(ii), ...
                    obj.hpsCoreTrainerParams{:} );
                obj.hpsCVtrainer.abortPerfMin = max( max( hps.perfs ), obj.abortPerfMin );
                obj.hpsCVtrainer.run();
                hps.perfs(ii) = obj.hpsCVtrainer.getPerformance().avg;
            end
            verboseFprintf( obj, 'Done\n' );
            if obj.hpsRefineStages > 0
                verboseFprintf( obj, '\n== HPS refine stage...\n' );
                refinedHpsTrainer = obj.createRefineGridTrainer( hps );
                refinedHpsTrainer.run();
                hps.params = [hps.params; refinedHpsTrainer.hpsSets.params];
                hps.perfs = [hps.perfs; refinedHpsTrainer.hpsSets.perfs];
            end
            obj.hpsSets = obj.sortHpsSetsByPerformance( hps );
            verboseFprintf( obj, ['\n\n==============================\n' ...
                                      'HPS sets:\n' ...
                                      '==============================\n'] );
            for ii = 1 : numel( obj.hpsSets.perfs )
                paramNames = fieldnames( obj.hpsSets.params );
                for jj = 1 : numel( paramNames )
                    verboseFprintf( obj, [paramNames{jj} ': %f \t '], obj.hpsSets.params(ii).(paramNames{jj}) );
                end
                verboseFprintf( obj, '== %f\n', obj.hpsSets.perfs(ii) );
            end
            if obj.trainWithBestHps
                obj.coreTrainer.setParameters( false, ...
                    obj.hpsSets.params(end), ...
                    'maxDataSize', obj.finalMaxDataSize, ...
                    'maxTestDataSize', obj.maxTestDataSize, ...
                    obj.finalCoreTrainerParams{:} );
                obj.coreTrainer.setData( obj.trainSet, obj.testSet );
                verboseFprintf( obj, ['\n\n ---------------------------------------->>>\n' ...
                                           'Train with best HPS set on full trainSet...\n' ...
                                           '-------------------------------------------\n'] );
                obj.coreTrainer.run();
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = Models.HPSmodel();
            model.model = obj.coreTrainer.getModel();
            model.hpsSet = obj.hpsSets;
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
        function createHpsTrainer( obj )
            obj.hpsCVtrainer = ModelTrainers.CVtrainer( obj.coreTrainer );
            obj.hpsCVtrainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.hpsCVtrainer.setData( obj.trainSet, [] );
            obj.hpsCVtrainer.setNumberOfFolds( obj.hpsCvFolds );
        end
        %% -------------------------------------------------------------------------------
        
        function hpsSets = determineHyperparameterSets( obj )
            switch( lower( obj.hpsMethod ) )
                case 'grid'
                    hpsSets = obj.getHpsGridSearchSets();
                case 'random'
                    hpsSets = obj.getHpsRandomSearchSets();
                case 'intelligrid'
                    error( 'not implemented.' );
            end
        end
        %% -------------------------------------------------------------------------------

        function refinedHpsTrainer = createRefineGridTrainer( obj, hps )
            hps = obj.sortHpsSetsByPerformance( hps );
            refinedHpsTrainer = obj.refineGridTrainer( hps );
            refinedHpsTrainer.setData( obj.trainSet, obj.testSet );
            refinedHpsTrainer.trainWithBestHps = false;
            newHpsMaxDataSize = obj.hpsMaxDataSize(min(2,numel( obj.hpsMaxDataSize )):end);
            newHpsSearchBudget = obj.hpsSearchBudget(min(2,numel( obj.hpsSearchBudget )):end);
            refinedHpsTrainer.setParameters( false, ...
                'hpsRefineStages', obj.hpsRefineStages - 1, ...
                'hpsMaxDataSize', newHpsMaxDataSize, ...
                'hpsSearchBudget', newHpsSearchBudget );
            refinedHpsTrainer.abortPerfMin = max( hps.perfs );
        end
        %% -------------------------------------------------------------------------------
        
        function hps = sortHpsSetsByPerformance( obj, hps )
            [hps.perfs,idx] = sort( hps.perfs );
            hps.params = hps.params(idx);
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        hpsSets = getHpsGridSearchSets( obj )
        hpsSets = getHpsRandomSearchSets( obj )
        refinedHpsTrainer = refineGridTrainer( obj, hps )
    end
        
end