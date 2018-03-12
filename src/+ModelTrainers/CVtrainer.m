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
        lastMaxFoldSize;
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
            obj.lastMaxFoldSize = 0;
            obj.recreateFolds = true;
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
            if nFolds ~= obj.nFolds
                obj.parallelFolds = [];
            end
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
            freemem = memReport() %#ok<*NOPRT,*NASGU> % for debugging
            if ModelTrainers.CVtrainer.useParallelComputing && pctInstalled && pctLicensed
                obj.buildModel_pct();
            else
                obj.buildModel_standard();
            end
            freemem = memReport() % for debugging
        end
        %% ----------------------------------------------------------------
        
        function buildModel_pct( obj, ~, ~, ~ )
            foldsPerformance_tmp = obj.foldsPerformance;
            if isempty( obj.parallelFolds )
                if isempty( gcp( 'nocreate' ) )
                    pc = parcluster();
                    pc_tmpDir = cleanPathFromRelativeRefs( fullfile( ...
                                             pwd, '..', 'parpool_tmps', ...
                                             ['parpool_tmp' buildCurrentTimeString()] ) );
                    mkdir( pc_tmpDir );
                    pc.JobStorageLocation = pc_tmpDir;
                    parpool( pc, min( obj.nFolds, feature( 'numcores' ) ) );
                end
                obj.parallelFolds = parallel.pool.Constant( obj.folds );
            end
            parallelFolds_tmp = obj.parallelFolds;
            trainers_tmp(obj.nFolds) = obj.trainer;
            trainers_tmp(obj.nFolds).setData( [], [] );
            for ff = 1 : obj.nFolds
                trainers_tmp(ff) = copy( trainers_tmp(obj.nFolds) );
            end
            foldsIdx = 1 : obj.nFolds;
            models_tmp = cell( obj.nFolds, 1 );
            freemem = memReport() % for debugging
            fmask = obj.featureMask;
            parfor ff = foldsIdx
                fprintf( '\nStarting run %d of CV... \n', ff );
                freemem = memReport() % for debugging
                foldsIdx_tmp = foldsIdx;
                foldsIdx_tmp(ff) = [];
                fc = cat( 1, parallelFolds_tmp.Value{foldsIdx_tmp} ); %#ok<PFBNS>
                foldCombi = struct( 'x', {cat( 1, fc(:).x )}, ...
                                    'y', {cat( 1, fc(:).y )}, ...
                                    'blockAnnotations', {cat( 1, fc(:).blockAnnotations )} );
                trainer_ff = trainers_tmp(ff);
                ModelTrainers.Base.featureMask( true, fmask ); % persistent variables are not copied to workers
                trainer_ff.setData( foldCombi, parallelFolds_tmp.Value{ff} );
                freemem = memReport() % for debugging
                trainer_ff.run();
                freemem = memReport() % for debugging
                foldsPerformance_tmp(ff) = double( trainer_ff.getPerformance() );
                fprintf( '\nDone with run %d of CV. Performance = %f\n\n', ...
                                                           ff, foldsPerformance_tmp(ff) );
                models_tmp{ff} = trainer_ff.getModel();
                freemem = memReport() % for debugging
            end
            obj.models = models_tmp;
            obj.foldsPerformance = foldsPerformance_tmp;
        end
        %% ----------------------------------------------------------------
        
        function buildModel_standard( obj, ~, ~, ~ )
            for ff = 1 : obj.nFolds
                foldsIdx = 1 : obj.nFolds;
                foldsIdx(ff) = [];
                fc = cat( 1, obj.folds{foldsIdx} ); 
                foldsRecombinedData = struct( 'x', {cat( 1, fc(:).x )}, ...
                                              'y', {cat( 1, fc(:).y )}, ...
                                              'blockAnnotations', {cat( 1, fc(:).blockAnnotations )} );
                obj.trainer.setData( foldsRecombinedData, obj.folds{ff} );
                verboseFprintf( obj, 'Starting run %d of CV... \n', ff );
                freemem = memReport() % for debugging
                obj.trainer.run();
                freemem = memReport() % for debugging
                obj.models{ff} = obj.trainer.getModel();
                obj.foldsPerformance(ff) = double( obj.trainer.getPerformance() );
                verboseFprintf( obj, '\nDone. Performance = %f\n\n', obj.foldsPerformance(ff) );
                maxPossiblePerf = mean( obj.foldsPerformance );
                freemem = memReport() % for debugging
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
            maxFoldDataSize = ceil( max( obj.trainer.maxDataSize / obj.nFolds, ...
                                         obj.trainer.maxTestDataSize ) );
            if ~obj.recreateFolds && (maxFoldDataSize == obj.lastMaxFoldSize), return; end
            obj.folds = obj.trainSet.splitInPermutedStratifiedFolds( obj.nFolds );
            for ff = 1 : obj.nFolds
                fprintf( '\nPreparing fold %d\n', ff );
                [x,y,~,~,ba] = ModelTrainers.Base.getSelectedData( obj.folds{ff}, ...
                                        maxFoldDataSize, obj.trainer.dataSelector, [], ...
                                                                            true, false );
                obj.folds{ff} = struct( 'x', {x}, 'y', {y}, 'blockAnnotations', {ba} );
            end
            obj.recreateFolds = false;
            obj.lastMaxFoldSize = maxFoldDataSize;
            obj.parallelFolds = [];
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