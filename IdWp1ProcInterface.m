classdef (Abstract) IdWp1ProcInterface < handle

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdWp1ProcInterface()
        end
        
        %%-----------------------------------------------------------------
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        
        %% function wp1flist = run( obj, idTrainData, className )
        %       wp1-process all wavs in idTrainData of class className
        %       save the results in mat-files
        run( obj, idTrainData, className )
        
    end
    
end

