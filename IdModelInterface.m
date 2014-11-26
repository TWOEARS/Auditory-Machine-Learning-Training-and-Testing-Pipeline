classdef (Abstract) IdModelInterface < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
    end
    
    %% --------------------------------------------------------------------
    methods
        
        % -----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        [y,score] = applyModel( obj, x )
    end

    %% --------------------------------------------------------------------
    methods (Static)
        
        function perf = getPerformance( model, testSet, positiveClass, perfMeasure )
            if isempty( testSet ), error( 'There is no testset to test on.' ); end
            x = testSet(:,:,'x');
            yTrue = testSet(:,:,'y',positiveClass);
            if isempty( x ), error( 'There is no data to test the model.' ); end
            yModel = model.applyModel( x );
            perf = perfMeasure( yTrue, yModel );
        end
        %% ----------------------------------------------------------------
    
    end
    
end

