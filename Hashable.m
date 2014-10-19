classdef (HandleCompatible) Hashable    
    % Interface for classes that provide a method to encode their status as 
    % a hashcode. 
    % Overwrite getHashObjects to leave out properties of hash calculation.
    % Can be superclass of handle or value class
    
    %%---------------------------------------------------------------------
    properties 
    end
    
    %%---------------------------------------------------------------------
    methods
        
        function hashcode = getHash( obj )
            hashMembers = obj.getHashObjects();
            hashcode = DataHash( hashMembers );
        end
        
        function hashMembers = getHashObjects( obj )
            mcdata = metaclass( obj );
            propsData = mcdata.PropertyList;
            warning off MATLAB:structOnObject
            propsStruct = struct( obj );
            warning on MATLAB:structOnObject
            hashMembers = {};
            for p = propsData'
                if p.Transient, continue; end
                if ~isfield( propsStruct, p.Name ), continue; end
                hashMembers{end+1} = propsStruct.(p.Name);
            end
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        
        
    end
    
    %%---------------------------------------------------------------------
    

    
    %%---------------------------------------------------------------------
    
end

