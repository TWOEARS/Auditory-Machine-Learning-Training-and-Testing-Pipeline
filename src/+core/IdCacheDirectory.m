classdef IdCacheDirectory < handle
    
    properties (SetAccess = protected)
    end
    
    properties (Access = protected)
        treeRoot;
        topCacheDirectory;
        cacheDirectoryFilename;
        cacheFileInfo;
        cacheFileRWsema;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdCacheDirectory()
            obj.treeRoot = core.IdCacheTreeElem();
            obj.cacheFileInfo = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
        end
        %% -------------------------------------------------------------------------------
        
        function delete( obj )
            obj.saveCacheDirectory();
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
            obj.topCacheDirectory = cleanPathFromRelativeRefs( topDir );
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
                obj.cacheDirChanged = true;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function getSingleProcessCacheAccess( obj )
        end
        %% -------------------------------------------------------------------------------
        
        function releaseSingleProcessCacheAccess( obj )
        end
        %% -------------------------------------------------------------------------------
        
        function saveCacheDirectory( obj, filename )
            if nargin < 2 && isempty( obj.cacheDirectoryFilename )
                filename = 'cacheDirectory.mat';
            end
            if ~isempty( [strfind( filename, '/' ), strfind( filename, '\' )] )
                error( 'filename supposed to be only file name without any path' );
            end
            obj.cacheDirectoryFilename = filename;
            if ~obj.cacheDirChanged, return; end
            cacheFilepath = [obj.topCacheDirectory filesep obj.cacheDirectoryFilename];
            cacheWriteFilepath = [cacheFilepath '.write'];
            cacheWriteSema = setfilesemaphore( cacheWriteFilepath );
            newCacheFileInfo = dir( cacheFilepath );
            if ~isempty( newCacheFileInfo ) && ...
                    ~isequalDeepCompare( newCacheFileInfo, obj.cacheFileInfo(cacheFilepath) )
                obj.cacheFileRWsema.getReadAccess();
                Parameters.dynPropsOnLoad( true, false );
                newCacheFile = load( cacheFilepath );
                Parameters.dynPropsOnLoad( true, true );
                obj.cacheFileRWsema.releaseReadAccess();
                obj.integrateOtherCacheDirectory( newCacheFile );
            end
            cacheTree = obj.treeRoot;
            save( cacheWriteFilepath, 'cacheTree' );
            obj.cacheFileRWsema.getWriteAccess();
            copyfile( cacheWriteFilepath, cacheFilepath ); % this blocks cacheFile shorter
            obj.cacheFileRWsema.releaseWriteAccess();
            delete( cacheWriteFilepath );
            removefilesemaphore( cacheWriteSema );
            obj.cacheDirChanged = false;
        end
        %% -------------------------------------------------------------------------------
        
        function loadCacheDirectory( obj, filename )
            if nargin < 2 && isempty( obj.cacheDirectoryFilename )
                filename = 'cacheDirectory.mat';
            end
            if ~isempty( [strfind( filename, '/' ), strfind( filename, '\' )] )
                error( 'filename supposed to be only file name without any path' );
            end
            obj.cacheDirectoryFilename = filename;
            cacheFilepath = [obj.topCacheDirectory filesep obj.cacheDirectoryFilename];
            if ~obj.cacheFileInfo.isKey( cacheFilepath )
                obj.cacheFileRWsema = ReadersWritersFileSemaphore( cacheFilepath );
                if exist( cacheFilepath, 'file' )
                    obj.cacheFileRWsema.getReadAccess();
                    Parameters.dynPropsOnLoad( true, false ); % don't load unnecessary stuff
                    obj.cacheFileInfo(cacheFilepath) = dir( cacheFilepath ); % for later comparison
                    cacheFile = load( cacheFilepath );
                    Parameters.dynPropsOnLoad( true, true );
                    obj.cacheFileRWsema.releaseReadAccess();
                    obj.treeRoot = cacheFile.cacheTree;
                    obj.cacheDirChanged = false;
                else
                    error( 'could not load %s', cacheFilepath );
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function integrateOtherCacheDirectory( otherCacheDir )
            error( 'TODO' );
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
