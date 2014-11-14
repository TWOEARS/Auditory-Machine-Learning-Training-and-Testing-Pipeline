classdef (Abstract) IdTrainerInterface < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainSet;
        testSet;
        positiveClass;
        performanceMeasure;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function setData( obj, trainSet, testSet )
            obj.trainSet = trainSet;
            if ~exist( 'testSet', 'var' ), testSet = []; end
            obj.testSet = testSet;
        end
        %% ----------------------------------------------------------------
        
        function setPositiveClass( obj, modelName )
            if ~isa( modelName, 'char' ), error( 'modelName must be a string.' ); end
            obj.positiveClass = modelName;
        end
        %% ----------------------------------------------------------------

        function setPerformanceMeasure( obj, newPerformanceMeasure )
            if ~isa( newPerformanceMeasure, 'function_handle' )
                error( ['newPerformanceMeasure must be a function handle pointing ', ...
                        'to the constructor of a PerformanceMeasure interface.'] );
            end
            obj.performanceMeasure = newPerformanceMeasure;
        end
        %% ----------------------------------------------------------------
        
        function model = getModel( obj )
            model = obj.giveTrainedModel();
            if ~isa( model, 'IdModelInterface' )
                error( 'giveTrainedModel must produce an IdModelInterface object.' );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function v = verbose( obj, newV )
            persistent verb;    % faking a static property
            if isempty( verb ), verb = false; end
            if nargin > 1
                if islogical( newV )
                    verb = newV;
                elseif ischar( newV ) && any( strcmpi( newV, {'true','on','set'} ) )
                    verb = true;
                elseif ischar( newV ) && any( strcmpi( newV, {'false','off','unset'} ) )
                    verb = false;
                else
                    error( 'wrong datatype for newV.' );
                end
            end
            v = verb;
        end
        %% -------------------------------------------------------------------------------
        
        function performance = getPerformance( obj )
            if isempty( obj.testSet ), error( 'There is no testset to test on.' ); end
            x = obj.testSet(:,:,'x');
            yTrue = obj.testSet(:,:,'y',obj.positiveClass);
            if isempty( x ), error( 'There is no data to test the model.' ); end
            verboseFprintf( obj, 'Applying model to test set...\n' );
            model = obj.getModel();
            yModel = model.applyModel( x );
            performance = obj.performanceMeasure( yTrue, yModel );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            [x,y] = obj.getPermutedTrainingData();
            obj.buildModel( x, y );
        end
        %% ----------------------------------------------------------------

        function [x,y] = getPermutedTrainingData( obj )
            x = obj.trainSet(:,:,'x');
            if isempty( x ), error( 'There is no data to train the model.' ); end
            y = obj.trainSet(:,:,'y',obj.positiveClass);
            permutationIdxs = randperm( length( y ) );
            x = x(permutationIdxs,:);
            y = y(permutationIdxs);
        end
        %% ----------------------------------------------------------------

        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        buildModel( obj, x, y )
    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        model = giveTrainedModel( obj )
    end
    
end

