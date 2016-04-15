classdef IdCacheTreeElem < handle
    
    properties (Access = {?Core.IdCacheDirectory})
        cfg;
        cfgSubs;
        path;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdCacheTreeElem( cfg, path )
            if nargin < 1, cfg = []; end
            if nargin < 2, path = []; end
            obj.cfg = cfg;
            obj.cfgSubs = containers.Map('KeyType','char','ValueType','any');
            obj.path = path;
        end
        %% -------------------------------------------------------------------------------
        
        function treeNode = getCfg( obj, cfgList, createIfMissing )
            if nargin < 3, createIfMissing = false; end
            if isempty( cfgList ), treeNode = obj; return; end
            treeNode = obj;
            for ii = 1 : numel( cfgList )
                subTreeNode = [];
                cfgName = cfgList(ii).fieldname;
                cfgField = cfgList(ii).field;
                if treeNode.cfgSubs.isKey( cfgName )
                    subTreeNodes = treeNode.cfgSubs(cfgName);
                else
                    subTreeNodes = [];
                end
                for jj = 1 : numel( subTreeNodes )
                    subcfg = subTreeNodes(jj).cfg;
                    subcfgEqualsCfg = isequalDeepCompare( subcfg, cfgField );
                    if subcfgEqualsCfg
                        subTreeNode = subTreeNodes(jj);
                        break;
                    end
                end
                if isempty( subTreeNode )
                    if createIfMissing
                        newSubTrees = [Core.IdCacheTreeElem( cfgField ) subTreeNodes];
                        treeNode.cfgSubs(cfgName) = newSubTrees;
                        subTreeNode = newSubTrees(1);
                    else
                        return;
                    end
                end
                treeNode = subTreeNode;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function subTreeNode = getCfgSubtree( obj, cfgFieldName, cfg, createIfMissing )
            if nargin < 4, createIfMissing = false; end
            subTreeNode = [];
            subTreeNodes = obj.getCfgSubtrees( cfgFieldName );
            for ii = 1 : numel( subTreeNodes )
                subcfg = subTreeNodes(ii).cfg;
                subcfgEqualsCfg = isequalDeepCompare( subcfg, cfg );
                if subcfgEqualsCfg
                    subTreeNode = subTreeNodes(ii);
                    return;
                end
            end
            if createIfMissing
                newSubTrees = [Core.IdCacheTreeElem( cfg ) subTreeNodes];
                obj.cfgSubs(cfgFieldName) = newSubTrees;
                subTreeNode = newSubTrees(1);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function subTreeNodes = getCfgSubtrees( obj, cfgFieldName )
            subTreeNodes = [];
            if obj.cfgSubs.isKey( cfgFieldName )
                subTreeNodes = obj.cfgSubs(cfgFieldName);
            end
        end
        %% -------------------------------------------------------------------------------
       
        function integrateOtherTreeNode( obj, otherNode )
            if ~isequalDeepCompare( obj.cfg, otherNode.cfg )
                error( 'this should not happen' );
            end
            if ~strcmp( obj.path, otherNode.path )
                if ~isempty( obj.path ) && ~isempty( otherNode.path )
                    copyfile( fullfile( obj.path, '*' ), ...
                              fullfile( otherNode.path, filesep ) );
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
