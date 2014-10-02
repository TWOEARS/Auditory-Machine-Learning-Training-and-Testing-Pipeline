classdef RatemapPlusDeltasBlockmean < IdFeatureProcInterface

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        deltasLevels;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = RatemapPlusDeltasBlockmean( deltasLevels )
            obj = obj@IdFeatureProcInterface();
            obj.deltasLevels = deltasLevels;
        end
        
        %%-----------------------------------------------------------------
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
end