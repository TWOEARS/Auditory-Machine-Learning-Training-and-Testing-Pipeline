classdef CVtrainer < IdTrainerInterface

    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainer;
        nFolds;
        folds;
        foldsPerformance;
    end

    %% --------------------------------------------------------------------
    properties (SetAccess = public)
        abortPerfMin;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = CVtrainer( trainer )
            if ~isa( trainer, 'IdTrainerInterface' )
                error( 'trainer must implement IdTrainerInterface' );
            end
            obj.trainer = trainer;
            obj.nFolds = 5;
            obj.abortPerfMin = 0;
        end
        %% ----------------------------------------------------------------
        
        function setPositiveClass( obj, modelName )
            setPositiveClass@IdTrainerInterface( obj, modelName );
            obj.trainer.setPositiveClass( modelName );
        end
        %% ----------------------------------------------------------------

        function setPerformanceMeasure( obj, newPerformanceMeasure )
            setPerformanceMeasure@IdTrainerInterface( obj, newPerformanceMeasure );
            obj.trainer.setPerformanceMeasure( newPerformanceMeasure );
        end
        %% ----------------------------------------------------------------

        function setNumberOfFolds( obj, nFolds )
            if nFolds < 2, error( 'CV cannot be executed with less than two folds.' ); end
            obj.nFolds = nFolds;
        end
        %% ----------------------------------------------------------------
        
        function run( obj )
            obj.trainer.verbose = obj.verbose;
            obj.createFolds();
            obj.foldsPerformance = ones( obj.nFolds, 1 );
            for ff = 1 : obj.nFolds
                foldsRecombinedData = obj.getAllFoldsButOne( ff );
                obj.trainer.setData( foldsRecombinedData, obj.folds{ff} );
                verboseFprintf( obj, 'Starting run %d of CV... ', ff );
                obj.trainer.run();
                obj.foldsPerformance(ff) = double( obj.trainer.getPerformance() );
                verboseFprintf( obj, 'Done. Performance = %f\n', obj.foldsPerformance(ff) );
                maxPossiblePerf = mean( obj.foldsPerformance );
                if (ff < obj.nFolds) && (maxPossiblePerf <= obj.abortPerfMin)
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
        
        function model = giveTrainedModel( obj )
            error( 'At the moment, CVtrainers do not return models.' );
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)

        function createFolds( obj )
            obj.folds = obj.trainSet.splitInPermutedStratifiedFolds( obj.nFolds );
        end
        %% ----------------------------------------------------------------
        
        function foldCombi = getAllFoldsButOne( obj, exceptIdx )
            foldsIdx = 1 : obj.nFolds;
            foldsIdx(exceptIdx) = [];
            foldCombi = IdentTrainPipeData.combineData( obj.folds{foldsIdx} );
        end
        %% ----------------------------------------------------------------

    end
    
end