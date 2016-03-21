classdef IdCacheTreeElem < handle
    
    properties
        cfg;
        cfgSubs;
        path;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdCacheTreeElem()
            obj.cfg = [];
            obj.cfgSubs = containers.Map('KeyType','char','ValueType','any');
            obj.path = [];
        end
        %% -------------------------------------------------------------------------------
    end
    
end
