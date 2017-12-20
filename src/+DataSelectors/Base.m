classdef (Abstract) Base < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        data;
        verboseOutput = '';
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = connectData( obj, data )
            obj.data = data;
        end
        % -----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        [selectFilter] = getDataSelection( obj, sampleIdsIn, maxDataSize )
    end
    
end

