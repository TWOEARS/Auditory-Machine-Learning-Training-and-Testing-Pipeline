classdef (Abstract) FeatureProcInterface < handle

    %% --------------------------------------------------------------------
    methods (Abstract)
        afeRequests = getAFErequests( obj )
        outputDeps = getInternOutputDependencies( obj )
        x = makeDataPoint( obj, afeData )
    end
    
end

