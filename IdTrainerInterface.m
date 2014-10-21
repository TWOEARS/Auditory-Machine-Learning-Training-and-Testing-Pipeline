classdef (Abstract) IdTrainerInterface < IdProcInterface

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdTrainerInterface()
            obj = obj@IdProcInterface();
        end
        
        %%-----------------------------------------------------------------
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        
    end
    
end

