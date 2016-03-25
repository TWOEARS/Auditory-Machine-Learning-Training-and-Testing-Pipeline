classdef IdCacheDirectory < handle
    
    properties (SetAccess = protected)
    end
    
    properties (Access = protected)
        treeRoot;
        topCacheDirectory;
        cacheDirectoryFilename = 'cacheDirectory.mat';
        cacheFileInfo;
        cacheFileRWsema;
        cacheDirChanged;
        cacheSingleProcessSema;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdCacheDirectory()
            obj.treeRoot = core.IdCacheTreeElem();
            obj.cacheFileInfo = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            obj.cacheDirChanged = false;
        end
        %% -------------------------------------------------------------------------------
        
        function delete( obj )
            obj.saveCacheDirectory();
            obj.releaseSingleProcessCacheAccess();
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
            if nargin < 3, createIfnExist = true; end
            treeNode = obj.findCfgTreeNode( cfg, createIfnExist );
            if isempty( treeNode ), return; end
            if isempty( treeNode.path ) && createIfnExist
                treeNode.path = obj.makeNewCacheFolder( cfg );
                obj.cacheDirChanged = true;
            end
            filepath = treeNode.path;
        end
        %% -------------------------------------------------------------------------------
        
        function folderName = makeNewCacheFolder( obj, cfg )
            timestr = buildCurrentTimeString( true );
            folderName = [obj.topCacheDirectory filesep 'cache' timestr];
            mkdir( folderName );
            save( [folderName filesep 'cfg.mat'], 'cfg' );
        end
        %% -------------------------------------------------------------------------------

        function getSingleProcessCacheAccess( obj )
            cacheFilepath = [obj.topCacheDirectory filesep obj.cacheDirectoryFilename];
            cacheSpFilepath = [cacheFilepath '.singleProcess'];
            obj.cacheSingleProcessSema = setfilesemaphore( cacheSpFilepath );
        end
        %% -------------------------------------------------------------------------------
        
        function releaseSingleProcessCacheAccess( obj )
            removefilesemaphore( obj.cacheSingleProcessSema );
        end
        %% -------------------------------------------------------------------------------
        
        function saveCacheDirectory( obj, filename )
            if nargin < 2 
                filename = obj.cacheDirectoryFilename;
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
                obj.treeRoot.integrateOtherTreeNode( newCacheFile.cacheTree );
            end
            cacheTree = obj.treeRoot;
            save( cacheWriteFilepath, 'cacheTree' );
            obj.cacheFileRWsema.getWriteAccess();
            copyfile( cacheWriteFilepath, cacheFilepath ); % this blocks cacheFile shorter
            obj.cacheFileInfo(cacheFilepath) = dir( cacheFilepath );
            obj.cacheFileRWsema.releaseWriteAccess();
            delete( cacheWriteFilepath );
            removefilesemaphore( cacheWriteSema );
            obj.cacheDirChanged = false;
        end
        %% -------------------------------------------------------------------------------
        
        function loadCacheDirectory( obj, filename )
            if nargin < 2
                filename = obj.cacheDirectoryFilename;
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
                    warning( 'could not load %s', cacheFilepath );
                    obj.cacheFileInfo(cacheFilepath) = [];
                end
            end
        end
        %% -------------------------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function treeNode = findCfgTreeNode( obj, cfg, createIfMissing )
            ucfg = core.IdCacheDirectory.unfoldCfgStruct( cfg );
            treeNode = obj.treeRoot.findCfg( ucfg, createIfMissing );
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
        
    end
    
end
