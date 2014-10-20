classdef (Abstract) IdWp2ProcInterface < IdProcInterface
    %% responsible for transforming wp1 files into wp2 acoustic cues files
    %   this includes transforming onset/offset labels to the earsignals'
    %   time line, as it is the only point where the "truth" is known.

    %%---------------------------------------------------------------------
    properties (SetAccess = private, Transient)
        buildWp1FileName;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdWp2ProcInterface()
            obj = obj@IdProcInterface();
        end
        
        %%-----------------------------------------------------------------
            
        function setWp1FileNameBuilder( obj, wp1FileNameBuilder )
            obj.buildWp1FileName = wp1FileNameBuilder;
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
    
        registerRequests( obj, wp2Requests )
        run( obj )

    end
    
end

