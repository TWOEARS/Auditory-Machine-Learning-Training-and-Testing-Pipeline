classdef (Abstract) IdTrainerInterface < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainSet;
        testSet;
        positiveClass;
        performanceMeasure;
    end
    
    %% --------------------------------------------------------------------
    properties (Access = public)
        verbose = false;
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
        %% ----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        run( obj )
        performance = getPerformance( obj )
    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        model = giveTrainedModel( obj )
    end
    
end

