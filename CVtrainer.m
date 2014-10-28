classdef CVtrainer < IdTrainerInterface

    % ---------------------------------------------------------------------
    properties (SetAccess = protected)
        trainer;
        nFolds;
        folds;
    end
    
    % ---------------------------------------------------------------------
    methods

        function obj = CVtrainer( trainer )
            if ~isa( trainer, 'IdTrainerInterface' )
                error( 'trainer must implement IdTrainerInterface' );
            end
            obj.trainer = trainer;
        end
        % -----------------------------------------------------------------

        function setNumberOfFolds( obj, nFolds )
            obj.nFolds = nFolds;
        end
        % -----------------------------------------------------------------
        
        function setPositiveClass( obj, modelName )
        end
        % -----------------------------------------------------------------
        
        function run( obj )
        end
        % -----------------------------------------------------------------
        
        function performance = getPerformance( obj )
        end
        % -----------------------------------------------------------------
        
        function model = getModel( obj )
        end
        % -----------------------------------------------------------------
        
    end
    
    % ---------------------------------------------------------------------
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