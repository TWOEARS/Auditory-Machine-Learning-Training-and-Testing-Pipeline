classdef IdCacheDirectory < handle
    
    properties (SetAccess = protected)
    end
    
    properties (Access = protected)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdCacheDirectory()
        end
        %% -------------------------------------------------------------------------------
        
        function setCacheFilename( obj, cfg, filename )
            
        end
        %% -------------------------------------------------------------------------------
        
        function filepath = getCacheFilepath( obj, cfg )
            filepath = [];
            treeNode = obj.findCfgTreeNode( cfg, false );
            if ~isempty( treeNode ) && ~isempty( treeNode.path )
                filepath = treeNode.path; 
            end
        end
        %% -------------------------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function treeNode = findCfgTreeNode( obj, cfg, createIfMissing )
            "unfold" cfg struct-ure
            sort cfg fields by name
            take first one => a (is "leaf": matrix, cell, or object)
            [pos1] in cfg-db search tree's top level: search for {a-name,a-contents}
            if not found 
                and createIfMissing: with rest of unfolded cfg structure, create and return tree node
                not createIfMissing: return []
            if found: 
                if there is no next cfg leaf, return tree node
                else take next cfg leaf, go to pos1
        end
        %% -------------------------------------------------------------------------------
    end
    
end
