classdef (Abstract) FeatureProcInterface < handle

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureProcInterface()
        end

    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        wp2Requests = getWp2Requests( obj )
        x = makeDataPoint( obj, wp2data )
    end
    
end

