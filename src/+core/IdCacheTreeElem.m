classdef IdCacheTreeElem < handle
    
    properties
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
        
        function treeNode = findCfg( obj, cfgList, createIfMissing )
            cfgFieldNames = fieldnames( cfgList );
            treeNode = obj;
            for ff = 1 : numel( cfgFieldNames )
                cfgFieldName = cfgFieldNames{ff};
                cfgField = cfgList.(cfgFieldName);
                subTreeNode = treeNode.getCfgSubtree( treeNode, cfgFieldName, cfgField );
                if ~isempty( subTreeNode )
                    treeNode = subTreeNode;
                else
                    if nargin > 2 && createIfMissing
                        restCfgList = rmfield( cfgList, cfgFieldNames(1:ff-1) );
                        treeNode = core.IdCacheDirectory.createCfgTree( treeNode, restCfgList );
                    else
                        treeNode = [];
                    end
                    return;
                end
            end
        end
        %% -------------------------------------------------------------------------------
         
        function cfgLeafNode = createCfgTree( obj, cfgList )
            cfgFieldNames = fieldnames( cfgList );
            treeNode = obj;
            for ff = 1 : numel( cfgFieldNames )
                cfgFieldName = cfgFieldNames{ff};
                cfgField = cfgList.(cfgFieldName);
                existingTreeNodes = treeNode.getCfgSubtrees( cfgFieldName );
                newSubTrees = [core.IdCacheTreeElem( cfgField ) existingTreeNodes];
                treeNode.cfgSubs(cfgFieldName) = newSubTrees;
                treeNode = newSubTrees(1);
            end
            cfgLeafNode = treeNode;
        end
        %% -------------------------------------------------------------------------------
        
        function subTreeNode = getCfgSubtree( obj, cfgFieldName, cfg )
            subTreeNode = [];
            subTreeNodes = obj.getCfgSubtrees( cfgFieldName );
            for ii = 1 : numel( subTreeNodes )
                if isequalDeepCompare( subTreeNodes(ii).cfg, cfg )
                    subTreeNode = subTreeNodes(ii);
                    return;
                end
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
