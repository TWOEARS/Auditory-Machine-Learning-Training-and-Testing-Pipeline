classdef IdCacheDirectory < handle
    
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
            obj.treeRoot = Core.IdCacheTreeElem();
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
            if nargin < 3, createIfnExist = false; end
            treeNode = obj.findCfgTreeNode( cfg, createIfnExist );
            if isempty( treeNode ), filepath = []; return; end
            if isempty( treeNode.path ) && createIfnExist
                treeNode.path = obj.makeNewCacheFolder( cfg );
                obj.cacheDirChanged = true;
            end
            filepath = treeNode.path;
        end
        %% -------------------------------------------------------------------------------

        function getSingleProcessCacheAccess( obj )
            if ~isempty( obj.cacheSingleProcessSema ), return; end
            cacheFilepath = [obj.topCacheDirectory filesep obj.cacheDirectoryFilename];
            cacheSpFilepath = [cacheFilepath '.singleProcess'];
            obj.cacheSingleProcessSema = setfilesemaphore( cacheSpFilepath );
        end
        %% -------------------------------------------------------------------------------
        
        function releaseSingleProcessCacheAccess( obj )
            removefilesemaphore( obj.cacheSingleProcessSema );
            obj.cacheSingleProcessSema = [];
        end
        %% -------------------------------------------------------------------------------
        
        function saveCacheDirectory( obj, filename )
            if nargin < 2 
                filename = obj.cacheDirectoryFilename;
            end
            if ~isempty( [strfind( filename, '/' ), strfind( filename, '\' )] )
                error( 'filename supposed to be only file name without any path' );
            end
            if ~obj.cacheDirChanged, return; end
            obj.cacheDirectoryFilename = filename;
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
            else
                newCacheFileInfo = dir( cacheFilepath );
                if ~isempty( newCacheFileInfo ) && ~isequalDeepCompare( ...
                                      newCacheFileInfo, obj.cacheFileInfo(cacheFilepath) )
                    obj.cacheFileRWsema.getReadAccess();
                    Parameters.dynPropsOnLoad( true, false );
                    newCacheFile = load( cacheFilepath );
                    Parameters.dynPropsOnLoad( true, true );
                    obj.cacheFileRWsema.releaseReadAccess();
                    obj.cacheDirChanged = ...
                            obj.treeRoot.integrateOtherTreeNode( newCacheFile.cacheTree );
                        obj.cacheFileInfo(cacheFilepath) = newCacheFileInfo;
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function maintenance( obj )
            cDirs = dir( [obj.topCacheDirectory filesep 'cache.*'] );
            cacheDirs = cell( 0, 3 );
            for ii = 1 : numel( cDirs )
                if ~exist( [obj.topCacheDirectory filesep cDirs(ii).name filesep 'cfg.mat'], 'file' )
                    fprintf( '''%s'' does not contain a ''cfg.mat''.\nPress key to continue\n', cDirs(ii).name );
                    pause;
                else
                    cacheDirs{end+1,1} = [obj.topCacheDirectory filesep cDirs(ii).name];
                    cl = load( [cacheDirs{end,1} filesep 'cfg.mat'], 'cfg' );
                    cacheDirs{end,2} = Core.IdCacheDirectory.unfoldCfgStruct( cl.cfg );
                end
            end
            for ii = 1 : size( cacheDirs, 1 )-1
            for jj = ii+1 : size( cacheDirs, 1 )
                if isequalDeepCompare( cacheDirs{ii,2}, cacheDirs{jj,2} )
                    cacheDirs{ii,3} = [cacheDirs{ii,3} jj];
                    cacheDirs{jj,3} = [cacheDirs{jj,3} ii];
                end
            end
            end
            fprintf( '-> findAllLeaves\n' );
            [leaves, ucfgs] = obj.treeRoot.findAllLeaves( [] );
            if numel( leaves ) == 1  && leaves(1) == obj.treeRoot
                leaves = [];
                ucfgs = {};
            end
            remCfgs = {};
            deleteCdIdxs = [];
            fprintf( '-> check leaves ' );
            for ii = 1 : numel( leaves )
                leafPath = leaves(ii).path;
                cdIdx = find( strcmp( leafPath, cacheDirs(:,1) ) );
                if isempty( cdIdx )
                    remCfgs{end+1} = ucfgs{ii};
                elseif ~isequalDeepCompare( ucfgs{ii}, cacheDirs{cdIdx,2} )
                    remCfgs{end+1} = ucfgs{ii};
                elseif ~isempty( cacheDirs{cdIdx,3} )
                    for jj = cacheDirs{cdIdx,3}
                        fprintf( ':' );
                        duplDir = cacheDirs{jj,1};
                        fprintf( '\ncopy from ''%s'' to ''%s''\n', fullfile( leafPath, '*' ), fullfile( duplDir, filesep ) );
                        copyfile( fullfile( leafPath, '*' ), fullfile( duplDir, filesep ) );
                        rmdir( leafPath, 's' );
                        movefile( duplDir, leafPath );
                    end
                    deleteCdIdxs = [deleteCdIdxs cdIdx cacheDirs{cdIdx,3}];
                else
                    deleteCdIdxs = [deleteCdIdxs cdIdx];
                end
                fprintf( '%d/%d ', ii, numel( leaves ) );
            end
            fprintf( '\n' );
            [cacheDirs{deleteCdIdxs,:}] = deal( [] );
            fprintf( '-> deleteCfg ' );
            for ii = 1 : numel( remCfgs )
                obj.treeRoot.deleteCfg( remCfgs{ii} );
                obj.cacheDirChanged = true;
                fprintf( '%d/%d ', ii, numel( remCfgs ) );
            end
            fprintf( '\n' );
            ii = 1;
            fprintf( '-> unregistered duplicates ' );
            while any( false == cellfun( @isempty, cacheDirs(:,3) ) )
                if ~isempty( cacheDirs{ii,3} )
                    fprintf( '%d/%d ', ii, sum( ~cellfun( @isempty, cacheDirs(:,3) ) ) );
                    for jj = cacheDirs{ii,3}
                        fprintf( ':' );
                        duplDir = cacheDirs{jj,1};
                        fprintf( '\ncopy from ''%s'' to ''%s''\n', fullfile( duplDir, '*' ), fullfile( cacheDirs{ii,1}, filesep ) );
                        copyfile( fullfile( duplDir, '*' ), fullfile( cacheDirs{ii,1}, filesep ) );
                        rmdir( duplDir, 's' );
                    end
                    [cacheDirs{cacheDirs{ii,3},:}] = deal( [] );
                    cacheDirs{ii,3} = [];
                else
                    ii = ii + 1;
                end
            end
            fprintf( '\n' );
            cacheDirs(all( cellfun(@isempty,cacheDirs), 2 ),:) = [];
            fprintf( '-> add unregistered ' );
            for ii = 1 : size( cacheDirs, 1 )
                newCacheLeaf = obj.treeRoot.getCfg( cacheDirs{ii,2}, true );
                newCacheLeaf.path = cacheDirs{ii,1};
                obj.cacheDirChanged = true;
                fprintf( '%d/%d ', ii, size( cacheDirs, 1 ) );
            end
            fprintf( '\n' );
            fprintf( '-> saveCacheDirectory\n' );
            obj.saveCacheDirectory();
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function treeNode = findCfgTreeNode( obj, cfg, createIfMissing )
            if nargin < 3, createIfMissing = false; end
            ucfg = Core.IdCacheDirectory.unfoldCfgStruct( cfg );
            treeNode = obj.treeRoot.getCfg( ucfg, createIfMissing );
        end
        %% -------------------------------------------------------------------------------
        
        function folderName = makeNewCacheFolder( obj, cfg )
            timestr = buildCurrentTimeString( true );
            folderName = [obj.topCacheDirectory filesep 'cache' timestr];
            mkdir( folderName );
            save( [folderName filesep 'cfg.mat'], 'cfg' );
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Static)
        
        function ucfg = unfoldCfgStruct( cfg, sortUcfgArray, prefix )
            if ~isstruct( cfg )
                error( 'cfg has to be struct' ); 
            end
            if numel( cfg ) > 1
                error( 'cfg must not be array' );
            end
            if nargin < 2, sortUcfgArray = true; end
            if nargin < 3
                prefix = ''; 
            else
                prefix = [prefix '_'];
            end
            cfgFieldnames = fieldnames( cfg );
            cfgSubCfgIdxs = cellfun( @(cf)(isstruct( cfg.(cf) )), cfgFieldnames );
            subCfgFieldnames = cfgFieldnames(cfgSubCfgIdxs);
            uSubCfgs = cellfun( ...
                   @(fn)(Core.IdCacheDirectory.unfoldCfgStruct( cfg.(fn), ...
                                                                false, [prefix fn] )),...
                   subCfgFieldnames, 'UniformOutput', false );
            cfg = rmfield( cfg, cfgFieldnames(cfgSubCfgIdxs) );
            cfgFieldnames = cfgFieldnames(~cfgSubCfgIdxs);
            if isempty( cfgFieldnames )
                ucfg = struct('fieldname',{},'field',{});
            else
                ucfg = cellfun( @(sf,fn)(struct('fieldname',[prefix fn],'field',{sf})),...
                                  struct2cell( cfg ), cfgFieldnames );
            end
            ucfg = vertcat( ucfg, uSubCfgs{:} );
            if sortUcfgArray
                [~, order] = sort( {ucfg.fieldname} );
                ucfg = ucfg(order);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function standaloneMaintain( cacheTopDir )
            cache = Core.IdCacheDirectory();
            cache.setCacheTopDir( cacheTopDir );
            cache.loadCacheDirectory();
            cache.maintenance();
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end
