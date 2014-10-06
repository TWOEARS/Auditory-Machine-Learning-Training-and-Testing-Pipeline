classdef Hashable < handle

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function hash = getHash( obj, maxRecursionLevel )
            if ~exist( 'maxRecursionLevel', 'var' ), maxRecursionLevel = 10; end;
            hash = DataHash( obj, maxRecursionLevel );
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    %%---------------------------------------------------------------------
    
end

