classdef CVtrainer < ModelTrainers.Base

    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainer;
        parallelFolds;
        nFolds;
        folds;
        foldsPerformance;
        models;
        recreateFolds;
    end

    %% --------------------------------------------------------------------
    properties (SetAccess = public)
        abortPerfMin;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    
        function usePCT = useParallelComputing( newValue )
            persistent usePCT_staticVar;
            if isempty( usePCT_staticVar )
                usePCT_staticVar = false;
            end
            if nargin > 0
                if ~islogical( newValue ), newValue = logical( newValue ); end
                usePCT_staticVar = newValue;
            end
            usePCT = usePCT_staticVar;
        end
        
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = CVtrainer( trainer )
            if ~isa( trainer, 'ModelTrainers.Base' )
                error( 'trainer must implement ModelTrainers.Base' );
            end
            obj.trainer = trainer;
            obj.nFolds = 5;
            obj.abortPerfMin = -inf;
            obj.performanceMeasure = trainer.performanceMeasure;
        end
        %% ----------------------------------------------------------------

        function setNumberOfFolds( obj, nFolds )
            if ischar( nFolds ) && strcmpi( nFolds, 'preFolded' )
                nFolds = numel( obj.trainSet.folds );
            end
            if nFolds < 2, error( 'CV cannot be executed with less than two folds.' ); end
            if mod( numel( obj.trainSet.folds ), nFolds ) ~= 0
                warning( 'Executing CV with nFolds different from the number of set up disjunct data folds -- data will not be stratified wrt files on sources 2:n!' );
            end
            obj.nFolds = nFolds;
        end
        %% ----------------------------------------------------------------

        % override of ModelTrainers.Base's method
        function setData( obj, trainSet, testSet )
            if ~exist( 'testSet', 'var' ), testSet = []; end
            obj.recreateFolds = ~isequal( obj.trainSet, trainSet );
            setData@ModelTrainers.Base( obj, trainSet, testSet );
        end
        %% ----------------------------------------------------------------
        
        function run( obj )
            obj.buildModel();
        end
        %% ----------------------------------------------------------------
        
        function buildModel( obj, ~, ~, ~ )
            obj.trainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.createFolds();
            obj.foldsPerformance = ones( obj.nFolds, 1 );
            pctInstalled = ~isempty( ver( 'distcomp' ) );
            pctLicensed = license( 'test', 'Distrib_Computing_Toolbox' );
            if ModelTrainers.CVtrainer.useParallelComputing && pctInstalled && pctLicensed
                obj.buildModel_pct();
            else
                obj.buildModel_standard();
            end
        end
        %% ----------------------------------------------------------------
        
        function buildModel_pct( obj, ~, ~, ~ )
            foldsPerformance_tmp = obj.foldsPerformance;
            if numel( obj.parallelFolds ) ~= obj.nFolds
                trainers_tmp(obj.nFolds) = obj.trainer;
                for ff = 1 : obj.nFolds
                    trainers_tmp(ff) = copy( trainers_tmp(obj.nFolds) );
                end
                obj.parallelFolds = parallel.pool.Constant( obj.folds );
            end
            parallelFolds_tmp = obj.parallelFolds;
            foldsIdx = 1 : obj.nFolds;
            parfor ff = foldsIdx
                fprintf( '\nStarting run %d of CV... \n', ff );
                foldsIdx_tmp = foldsIdx;
                foldsIdx_tmp(ff) = [];
                foldCombi = Core.IdentTrainPipeData.combineData( ...
                                                        parallelFolds_tmp{foldsIdx_tmp} ); %#ok<PFBNS>
                trainers_tmp(ff).setData( foldCombi, parallelFolds_tmp{ff} );
                trainers_tmp(ff).run();
                foldsPerformance_tmp(ff) = double( trainers_tmp(ff).getPerformance() );
                fprintf( '\nDone with run %d of CV. Performance = %f\n\n', ...
                                                           ff, foldsPerformance_tmp(ff) );
            end
            for ff = 1 : obj.nFolds
                obj.models{ff} = trainers_tmp(ff).getModel();
            end
            obj.foldsPerformance = foldsPerformance_tmp;
        end
        %% ----------------------------------------------------------------
        
        function buildModel_standard( obj, ~, ~, ~ )
            for ff = 1 : obj.nFolds
                foldsRecombinedData = obj.getAllFoldsButOne( ff );
                obj.trainer.setData( foldsRecombinedData, obj.folds{ff} );
                verboseFprintf( obj, 'Starting run %d of CV... \n', ff );
                obj.trainer.run();
                obj.models{ff} = obj.trainer.getModel();
                obj.foldsPerformance(ff) = double( obj.trainer.getPerformance() );
                verboseFprintf( obj, '\nDone. Performance = %f\n\n', obj.foldsPerformance(ff) );
                maxPossiblePerf = mean( obj.foldsPerformance );
                if (ff < obj.nFolds) && (maxPossiblePerf <= obj.abortPerfMin)
                    % assume mean performance so far is about right --
                    % important when using CV to not only judge about the
                    % best model
                    obj.foldsPerformance(ff+1:end) = mean( obj.foldsPerformance(1:ff) );
                    break;
                end
            end
        end
        %% ----------------------------------------------------------------
        
        function performance = getPerformance( obj )
            performance.avg = mean( obj.foldsPerformance );
            performance.std = std( obj.foldsPerformance );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( ~ ) %#ok<STOUT>
            error( 'cvtrainer -- which model do you want?' );
        end
        %% ----------------------------------------------------------------
        
        function createFolds( obj )
            if ~obj.recreateFolds, return; end
            obj.folds = obj.trainSet.splitInPermutedStratifiedFolds( obj.nFolds );
            obj.recreateFolds = false;
            obj.parallelFolds = {};
        end
        %% ----------------------------------------------------------------
        
        function foldCombi = getAllFoldsButOne( obj, exceptIdx )
            foldsIdx = 1 : obj.nFolds;
            foldsIdx(exceptIdx) = [];
            foldCombi = Core.IdentTrainPipeData.combineData( obj.folds{foldsIdx} );
        end
        %% ----------------------------------------------------------------

    end
    
end