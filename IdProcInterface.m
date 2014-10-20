classdef (Abstract) IdProcInterface < Hashable & handle
    %% identification training pipeline processor
    %
    
    %%---------------------------------------------------------------------
    properties (SetAccess = private, Transient)
        data;
        procFileNameExt;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdProcInterface()
        end
        
        %%-----------------------------------------------------------------

        function connectData( obj, data )
            obj.data = data;
        end
        
        %%-----------------------------------------------------------------

        function setProcFileNameExt( obj, procFileNameExt )
            obj.procFileNameExt = procFileNameExt;
        end
        
        %%-----------------------------------------------------------------

        function procFileName = buildProcFileName( obj, wavFileName )
             procFileName = [which(wavFileName) obj.procFileNameExt];
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

