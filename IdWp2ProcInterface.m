classdef (Abstract) IdWp2ProcInterface < Hashable & handle
    %% responsible for transforming wp1 files into wp2 acoustic cues files
    %   this includes transforming onset/offset labels to the earsignals'
    %   time line, as it is the only point where the "truth" is known.

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdWp2ProcInterface()
        end
        
        %%-----------------------------------------------------------------
            
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
    
        registerRequests( obj, wp2Requests )
        run( obj, data )

    end
    
end

