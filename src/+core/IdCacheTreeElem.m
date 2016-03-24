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
        
        function integrateOtherTreeNode( obj, otherNode )
            if ~isequalDeepCompare( obj.cfg, otherNode.cfg )
                error( 'this should not happen' );
            end
            if ~strcmp( obj.path, otherNode.path )
                if ~isempty( obj.path ) && ~isempty( otherNode.path )
                    copyfile( fullfile( obj.path, '*' ), fullfile( otherNode.path, filesep ) );
                    rmdir( obj.path, 's' );
                    obj.path = otherNode.path;
                end
                if isempty( obj.path ) && ~isempty( otherNode.path )
                    obj.path = otherNode.path;
                end
            end
            otherSubKeys = otherNode.cfgSubs.keys;
            for ii = 1 : numel( otherSubKeys )
                if obj.cfgSubs.isKey( otherSubKeys{ii} )
                    subCfgs = obj.cfgSubs(otherSubKeys{ii});
                    otherSubCfgs = otherNode.cfgSubs(otherSubKeys{ii});
                    for jj = 1 : numel( otherSubCfgs )
                        foundSubCfg = false;
                        for kk = 1 : numel( subCfgs )
                            if isequalDeepCompare( subCfgs(kk).cfg, otherSubCfgs(jj).cfg )
                                integrateOtherTreeNode( subCfgs(kk), otherSubCfgs(jj) );
                                foundSubCfg = true;
                                break;
                            end
                        end
                        if ~foundSubCfg
                            obj.cfgSubs(otherSubKeys{ii}) = [otherSubCfgs(jj) subCfgs];
                        end
                    end
                else
                    obj.cfgSubs(otherSubKeys{ii}) = otherNode.cfgSubs(otherSubKeys{ii});
                end
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
end
