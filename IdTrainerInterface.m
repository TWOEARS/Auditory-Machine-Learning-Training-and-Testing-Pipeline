classdef (Abstract) IdTrainerInterface < handle
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        setData( obj, trainSet, testSet )
        setPositiveClass( obj, modelName )
        run( obj )
        performance = getPerformance( obj )
        model = getModel( obj )
    end
    
end

