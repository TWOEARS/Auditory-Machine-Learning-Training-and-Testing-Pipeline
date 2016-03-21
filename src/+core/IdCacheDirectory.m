classdef IdCacheDirectory < handle
    
    properties (SetAccess = protected)
    end
    
    properties (Access = protected)
        treeRoot;
        topCacheDirectory;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdCacheDirectory()
            obj.treeRoot = core.IdCacheTreeElem();
        end
        %% -------------------------------------------------------------------------------
        
        function setCacheTopDir( obj, topDir, createIfnExist )
            if ~exist( topDir, 'dir' ) 
                if nargin > 2 && createIfnExist
                    mkdir( topDir );
                else
                    error( '"%s" cannot be found', topDir );
                end
            end
            obj.topCacheDirectory = topDir;
        end
        %% -------------------------------------------------------------------------------
        
        function filepath = getCacheFilepath( obj, cfg, createIfnExist )
            if isempty( cfg ), filepath = obj.topCacheDirectory; return; end
            filepath = [];
            if nargin < 3, createIfnExist = false; end
            treeNode = obj.findCfgTreeNode( cfg, createIfnExist );
            if ~isempty( treeNode ) 
                if isempty( treeNode.path ) && nargin > 2 && createIfnExist
                    timestr = buildCurrentTimeString( true );
                    currentFolder = [obj.topCacheDirectory filesep 'cache' timestr];
                    mkdir( currentFolder );
                    treeNode.path = currentFolder;
                    save( [currentFolder filesep 'cfg.mat'], 'cfg' );
                end
                filepath = treeNode.path;
            end
        end
        %% -------------------------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function treeNode = findCfgTreeNode( obj, cfg, createIfMissing )
            ucfg = core.IdCacheDirectory.unfoldCfgStruct( cfg );
            cfgFields = fieldnames( ucfg );
            treeNode = obj.treeRoot;
            for ff = 1 : numel( cfgFields )
                cfgFieldName = cfgFields{ff};
                cfgField = ucfg.(cfgFieldName); % is "leaf": matrix, cell, or object
                nextTreeNode = core.IdCacheDirectory.getCfgSubtree( treeNode, cfgFieldName, cfgField );
                if ~isempty( nextTreeNode )
                    treeNode = nextTreeNode;
                else
                    if nargin > 2 && createIfMissing
                        for rf = ff : numel( cfgFields )
                            restUcfg.(cfgFields{rf}) = ucfg.(cfgFields{rf});
                        end
                        treeNode = core.IdCacheDirectory.createCfgTree( treeNode, restUcfg );
                    else
                        treeNode = [];
                    end
                    return;
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
        
        function ucfg = unfoldCfgStruct( cfg )
            if ~isstruct( cfg ), ucfg = cfg; return; end
            if numel( cfg ) > 1
                error( 'cfg must not be array' );
            end
            ucfg = cfg;
            cfgFields = fieldnames( cfg );
            for ff = 1 : numel( cfgFields )
                cfgFieldName = cfgFields{ff};
                if isstruct( cfg.(cfgFieldName) )
                    unfoldedCfgField = core.IdCacheDirectory.unfoldCfgStruct( cfg.(cfgFieldName) );
                    ucfg = rmfield( ucfg, cfgFieldName );
                    subCfgFields = fieldnames( unfoldedCfgField );
                    for sf = 1 : numel( subCfgFields )
                        subCfgFieldName = subCfgFields{sf};
                        nonStructName = [cfgFieldName '_' subCfgFieldName];
                        ucfg.(nonStructName) = unfoldedCfgField.(subCfgFieldName);
                    end
                end
            end
            ucfg = orderfields( ucfg );
        end
        %% -------------------------------------------------------------------------------
        
        function treeNode = createCfgTree( treeRoot, ucfg )
            cfgFields = fieldnames( ucfg );
            treeNode = treeRoot;
            for ff = 1 : numel( cfgFields )
                cfgFieldName = cfgFields{ff};
                nextTreeNode = core.IdCacheTreeElem();
                nextTreeNode.cfg = ucfg.(cfgFieldName);
                if isKey( treeNode.cfgSubs, cfgFieldName )
                    existingTreeNodes = treeNode.cfgSubs(cfgFieldName);
                    nextTreeNode(2:1+numel( existingTreeNodes )) = existingTreeNodes;
                end
                treeNode.cfgSubs(cfgFieldName) = nextTreeNode;
                treeNode = nextTreeNode(1);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function subTreeNode = getCfgSubtree( treeNode, cfgFieldName, cfgField )
            subTreeNode = [];
            if isKey( treeNode.cfgSubs, cfgFieldName )
                curSubTreeNodes = treeNode.cfgSubs(cfgFieldName);
                for ii = 1 : numel( curSubTreeNodes )
                    if isequalDeepCompare( curSubTreeNodes(ii).cfg, cfgField )
                        subTreeNode = curSubTreeNodes(ii);
                        return;
                    end
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end
