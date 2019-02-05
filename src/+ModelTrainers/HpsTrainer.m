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
            verboseFprintf( obj, '\nHyperparameter search CV...\n===========================\n' );
            curHpsStageStartIdx = 1;
            hps.params = [];
            hps.perfs = 0;
            while obj.hpsRefineStages > -1
                newHpsParams = obj.determineHyperparameterSets();
                hps.params = [hps.params; newHpsParams];
                for ii = curHpsStageStartIdx : numel( hps.params )
                    verboseFprintf( obj, '\nhps set %d...\n\n ', ii );
                    obj.coreTrainer.setParameters( false, ...
                        'maxDataSize', obj.hpsMaxDataSize(1), ...
                        'maxTestDataSize', obj.maxTestDataSize, ...
                        hps.params(ii), ...
                        obj.hpsCoreTrainerParams{:} );
                    obj.hpsCVtrainer.abortPerfMin = max( max( hps.perfs ), obj.abortPerfMin );
                    obj.hpsCVtrainer.run();
                    hps.perfs(ii) = obj.hpsCVtrainer.getPerformance().avg;
                    hps.stds(ii) = obj.hpsCVtrainer.getPerformance().std;
                    hps.dataSizes(ii) = obj.hpsMaxDataSize(1);
                    hps.testDataSizes(ii) = obj.maxTestDataSize;
                    hps.addInfo(ii) = obj.getHpsAddInfo();
                end
                obj.hpsRefineStages = obj.hpsRefineStages - 1;
                if obj.hpsRefineStages > -1
                    verboseFprintf( obj, '\n== HPS refine stage...\n' );
                    curHpsStageStartIdx = numel( hps.params ) + 1;
                    obj.refineHpsTrainer( hps );
                end
            end
            verboseFprintf( obj, 'Done\n' );
            obj.hpsSets = obj.sortHpsSetsByPerformance( hps );
            while obj.hpsSets.dataSizes(end) < max( obj.hpsSets.dataSizes(:) )
                verboseFprintf( obj, '\nchecking best hps set with max hps data size...\n ' );
                obj.coreTrainer.setParameters( false, ...
                    'maxDataSize', max( obj.hpsSets.dataSizes(:) ), ...
                    'maxTestDataSize', obj.maxTestDataSize(end), ...
                    obj.hpsSets.params(end), ...
                    obj.hpsCoreTrainerParams{:} );
                obj.hpsCVtrainer.abortPerfMin = max( obj.hpsSets.perfs(end), obj.abortPerfMin );
                obj.hpsCVtrainer.run();
                obj.hpsSets.perfs(end) = obj.hpsCVtrainer.getPerformance().avg;
                obj.hpsSets.stds(end) = obj.hpsCVtrainer.getPerformance().std;
                obj.hpsSets.addInfo(end) = obj.getHpsAddInfo();
                obj.hpsSets.dataSizes(end) = max( obj.hpsSets.dataSizes(:) );
                obj.hpsSets.testDataSizes(end) = obj.maxTestDataSize(end);
                obj.hpsSets = obj.sortHpsSetsByPerformance( obj.hpsSets );
            end
            verboseFprintf( obj, ['\n\n==============================\n' ...
                                      'HPS sets:\n' ...
                                      '==============================\n'] );
            for ii = 1 : numel( obj.hpsSets.perfs )
                paramNames = fieldnames( obj.hpsSets.params );
                for jj = 1 : numel( paramNames )
                    param = obj.hpsSets.params(ii).(paramNames{jj});
                    if isa( param, 'function_handle' )
                        param = func2str( param );
                        verboseFprintf( obj, [paramNames{jj} ': %s \t '], param );
                    else
                        verboseFprintf( obj, [paramNames{jj} ': %f \t '], param );
                    end
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
            model.featureMask = model.model.featureMask;
        end
        %% -------------------------------------------------------------------------------
        
        function hps = sortHpsSetsByPerformance( obj, hps )
            [hps.perfs,idx] = sort( hps.perfs );
            hps.stds = hps.stds(idx);
            hps.dataSizes = hps.dataSizes(idx);
            hps.testDataSizes = hps.testDataSizes(idx);
            hps.params = hps.params(idx);
            hps.addInfo = hps.addInfo(idx);
        end
        %% -------------------------------------------------------------------------------

        % to be possibly overwritten
        function hpsAddInfo = getHpsAddInfo( obj )
            hpsAddInfo = nan;
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

        function refineHpsTrainer( obj, hps )
            hps = obj.sortHpsSetsByPerformance( hps );
            obj.refineGridTrainer( hps );
            newHpsMaxDataSize = obj.hpsMaxDataSize(min(2,numel( obj.hpsMaxDataSize )):end);
            newHpsSearchBudget = obj.hpsSearchBudget(min(2,numel( obj.hpsSearchBudget )):end);
            obj.setParameters( false, ...
                'hpsMaxDataSize', newHpsMaxDataSize, ...
                'hpsSearchBudget', newHpsSearchBudget );
        end
        %% -------------------------------------------------------------------------------

        
    end

    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        hpsSets = getHpsGridSearchSets( obj )
        hpsSets = getHpsRandomSearchSets( obj )
        refineGridTrainer( obj, hps )
    end
        
end