classdef (Abstract) IdProcInterface < handle
    %% data file processor
    %
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        procName;
        cacheSystemDir;
        precedingProcCacheDir;
        externOutputDeps;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected, Transient = true)
        preloadedConfigs;
        preloadedConfigsChanged;
        pcFileInfo;
        pcRWsema = [];
        configChanged = true;
        currentFolder = [];
        preloadedPath = [];
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function delete(obj)
            obj.savePreloadedConfigs();
        end
        %% -----------------------------------------------------------------

        function savePreloadedConfigs( obj )
            pcFolders = obj.preloadedConfigs.keys;
            for dd = 1 : numel( pcFolders )
                if ~obj.preloadedConfigsChanged(pcFolders{dd}), return; end
                pc = obj.preloadedConfigs(pcFolders{dd});
                [pcFilename, pcWriteFilename] = obj.getPreloadedCfgsFilenames( pcFolders{dd} );
                sema = setfilesemaphore( pcWriteFilename );
                new_pcFileInfo = dir( pcFilename );
                if ~isempty( new_pcFileInfo ) && ...
                        ~isequalDeepCompare( new_pcFileInfo, obj.pcFileInfo(pcFolders{dd}) )
                    obj.pcRWsema.getReadAccess();
                    Parameters.dynPropsOnLoad( true, false );
                    new_pc = load( pcFilename, 'preloadedConfigs' );
                    Parameters.dynPropsOnLoad( true, true );
                    obj.pcRWsema.releaseReadAccess();
                    new_pcKeys = new_pc.preloadedConfigs.keys;
                    for jj = length( new_pcKeys ) : -1 : 1
                        k = new_pcKeys{jj};
                        if ~any( strcmp( k, pc.keys ) )
                            pc(k) = new_pc.preloadedConfigs(k);
                        end
                    end
                end
                save( pcWriteFilename, 'preloadedConfigs' );
                obj.pcRWsema.getWriteAccess();
                copyfile( pcWriteFilename, pcFilename ); % this blocks pcFilename much shorter
                obj.pcRWsema.releaseWriteAccess();
                delete( pcWriteFilename );
                removefilesemaphore( sema );
                obj.preloadedConfigsChanged(pcFolders{dd}) = false;
            end
        end
        %% -----------------------------------------------------------------
        
        function init( obj )
            obj.savePreloadedConfigs();
            obj.preloadedConfigs( pcFolder ) = ...
                containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            obj.preloadedConfigsChanged = ...
                containers.Map( 'KeyType', 'char', 'ValueType', 'logical' );
            obj.pcFileInfo( pcFolder ) = ...
                containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            obj.preloadedPath = [];
            obj.configChanged = true;
            obj.currentFolder = [];
        end
        %% -----------------------------------------------------------------
        
        function savePlaceholderFile( obj, inFilePath )
            obj.save( inFilePath, struct('dummy',[]) );
        end
        %% -----------------------------------------------------------------
        
        function out = saveOutput( obj, inFilePath )
            out = obj.getOutput();
            obj.save( inFilePath, out );
        end
        %% -----------------------------------------------------------------
        
        function out = processSaveAndGetOutput( obj, inFileName )
            if ~obj.hasFileAlreadyBeenProcessed( inFileName )
                obj.process( inFileName );
                out = obj.saveOutput( inFileName );
            else
                out = load( obj.getOutputFileName( inFileName ) );
            end
        end
        %% -----------------------------------------------------------------
        
        function outFileName = getOutputFileName( obj, inFilePath, currentFolder )
            if nargin < 3
                currentFolder = obj.getCurrentFolder( inFilePath );
            end
            if isempty( currentFolder )
                currentFolder = obj.createCurrentConfigFolder( inFilePath );
            end
            [~, fileName, fileExt] = fileparts( inFilePath );
            fileName = [fileName fileExt];
            outFileName = fullfile( currentFolder, [fileName obj.getProcFileExt] );
        end
        %% -----------------------------------------------------------------
        
        function [fileProcessed,precProcFileNeeded] = hasFileAlreadyBeenProcessed( obj, filePath, createFolder, checkPrecNeed )
            if isempty( filePath ), fileProcessed = false; return; end
            currentFolder = obj.getCurrentFolder( filePath );
            fileProcessed = ...
                ~isempty( currentFolder )  && ...
                exist( obj.getOutputFileName( filePath, currentFolder ), 'file' );
            if nargin > 2  &&  createFolder  &&  isempty( currentFolder )
                currentFolder = obj.createCurrentConfigFolder( filePath );
            end
            if ~fileProcessed && nargin > 3 && checkPrecNeed
                precProcFileNeeded = obj.needsPrecedingProcResult( filePath );
            else
                precProcFileNeeded = false;
            end
        end
        %% -----------------------------------------------------------------

        function setExternOutputDependencies( obj, externOutputDeps )
            obj.configChanged = true;
            obj.externOutputDeps = externOutputDeps;
        end
        %%-----------------------------------------------------------------
        
        function outputDeps = getOutputDependencies( obj )
            outputDeps = obj.getInternOutputDependencies();
            if ~isa( outputDeps, 'struct' )
                error( 'getInternOutputDependencies must combine values in a struct.' );
            end
            if isfield( outputDeps, 'extern' )
                error( 'Intern output dependencies must not contain field of name "extern".' );
            end
            if ~isempty( obj.externOutputDeps )
                outputDeps.extern = obj.externOutputDeps;
            end
        end
        %% -----------------------------------------------------------------

        function setCacheSystemDir( obj, cacheSystemDir )
            if exist( cacheSystemDir, 'dir' )
                obj.cacheSystemDir = which( cacheSystemDir ); % absolute path
            else
                error( 'cannot find direcotry "%s": does it exist?', cacheSystemDir ); 
            end
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function obj = IdProcInterface( procName )
            if nargin < 1
                classInfo = metaclass( obj );
                [classname1, classname2] = strtok( classInfo.Name, '.' );
                if isempty( classname2 ), obj.procName = classname1;
                else obj.procName = classname2(2:end); end
            else
                obj.procName = procName;
            end
            obj.externOutputDeps = [];
        end
        %% -----------------------------------------------------------------
        
        function precProcFileNeeded = needsPrecedingProcResult( obj, wavFileName )
            precProcFileNeeded = true; % this method is overwritten in Multi... subclasses
        end
        %% -----------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
        function out = save( obj, inFilePath, data )
%            inFilePath = which( inFilePath ); % ensure absolute path
            out = data;
            if isempty( inFilePath ), return; end
            currentFolder = obj.getCurrentFolder( inFilePath );
            if isempty( currentFolder )
                currentFolder = obj.createCurrentConfigFolder( inFilePath );
            end
            outFilename = obj.getOutputFileName( inFilePath, currentFolder );
            save( outFilename, '-struct', 'out' );
        end
        %% -----------------------------------------------------------------

        function saveOutputConfig( obj, configFileName )
            outputDeps = obj.getOutputDependencies();
            save( configFileName, '-struct', 'outputDeps' );
        end
        %% -----------------------------------------------------------------
        
        function currentFolder = getCurrentFolder( obj )
            if ~isempty( obj.currentFolder ) && ~obj.configChanged
                currentFolder = obj.currentFolder;
                return;
            end
            currentConfig = obj.getOutputDependencies();
            cacheFoldersDirResult = dir( [obj.cacheSystemDir filesep obj.procName '.2*'] );
            cacheFolders = {cacheFoldersDirResult.name};
            % shorten folderNames for faster processing (still unique)
            cacheFolders = cellfun( @(cf)(cf(length(obj.procName)+2:end)), ...
                                    cacheFolders, 'UniformOutput', false );
            currentFolder = [];
            if isempty( cacheFolders ), return; end
            % first: check to see whether the current search inquiry just resolves to the
            % last one that checked on the same cache folders
            if isempty( obj.preloadedPath )
                obj.preloadedPath = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            end
            allCacheFolders = strcat( cacheFolders{:} );
            if obj.preloadedPath.isKey( allCacheFolders )
                preloadedCfg = obj.preloadedPath(allCacheFolders);
                if isequalDeepCompare( preloadedCfg{2}, currentConfig )
                    currentFolder = preloadedCfg{1};
                    obj.configChanged = false;
                    obj.currentFolder = currentFolder;
                    return;
                end
            end
            % second: check cache folders whose configs are preloaded via preloadedConfigs
            for ii = length( cacheFolders ) : -1 : 1
                cfg = obj.getPreloadedCfg( obj.cacheSystemDir, cacheFolders{ii} );
                if ~isempty( cfg )
                    if isequalDeepCompare( currentConfig, cfg )
                        currentFolder = [obj.cacheSystemDir filesep ...
                                         obj.procName '.' cacheFolders{ii}];
                        cacheFolders = {}; % to completely avoid step three
                        break;
                    end
                    cacheFolders(ii) = []; % don't check in step three anymore
                end
            end
            % third: load configs and check
            for ii = length( cacheFolders ) : -1 : 1
                cfg = load( fullfile( ...
                    obj.cacheSystemDir, [obj.procName '.' cacheFolders{ii}], 'config.mat' ) );
                if isequalDeepCompare( currentConfig, cfg )
                    currentFolder = [obj.cacheSystemDir filesep ...
                                     obj.procName '.' cacheFolders{ii}];
                    obj.setPreloadedCfg( obj.cacheSystemDir, cacheFolders{ii}, cfg );
                    break;
                end
            end
            if ~isempty( currentFolder )
                obj.preloadedPath(allCacheFolders) = {currentFolder, currentConfig};
            end
            obj.configChanged = false;
            obj.currentFolder = currentFolder;
        end
        %% -----------------------------------------------------------------
        
        function currentFolder = createCurrentConfigFolder( obj )
            timestr = buildCurrentTimeString( true );
            currentFolder = [obj.cacheSystemDir filesep obj.procName timestr];
            mkdir( currentFolder );
            obj.saveOutputConfig( fullfile( currentFolder, 'config.mat' ) );
            cfg = load( fullfile( currentFolder, 'config.mat' ) );
            obj.setPreloadedCfg( obj.cacheSystemDir, cfgFolder, cfg );
            obj.configChanged = false;
            obj.currentFolder = currentFolder;
        end
        %% -----------------------------------------------------------------
        
        function loadPreloadedConfigs( obj, pcFolder )
            if ~isKey( obj.preloadedConfigs, pcFolder )
                pcFilename = obj.getPreloadedCfgsFilenames( pcFolder );
                obj.pcRWsema = ReadersWritersFileSemaphore( pcFilename );
                if exist( pcFilename, 'file' )
                    obj.pcRWsema.getReadAccess();
                    Parameters.dynPropsOnLoad( true, false ); % unnecessary stuff, don't load
                    obj.pcFileInfo( pcFolder ) = dir( pcFilename ); % for later comparison
                    pc = load( pcFilename );
                    Parameters.dynPropsOnLoad( true, true );
                    obj.pcRWsema.releaseReadAccess();
                    obj.preloadedConfigs( pcFolder ) = pc.preloadedConfigs;
                    obj.preloadedConfigsChanged( pcFolder ) = false;
                else
                    obj.preloadedConfigs( pcFolder ) = ...
                        containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
                end
            end
        end
        %% -----------------------------------------------------------------
        
        function [pcFn, pcwFn] = getPreloadedCfgsFilenames( obj, pcFolder )
            pcFn = [pcFolder filesep obj.procName '.preloadedConfigs.mat'];
            pcwFn = [pcFolder filesep obj.procName '.preloadedConfigs.write.mat'];
        end
        %% -----------------------------------------------------------------
        
        function setPreloadedCfg( obj, pcFolder, cfgFolder, cfg )
            obj.loadPreloadedConfigs( pcFolder );
            pc = obj.preloadedConfigs(pcFolder);
            pc(cfgFolder) = cfg;
            obj.preloadedConfigs(pcFolder) = pc;
            obj.preloadedConfigsChanged(pcFolder) = true;
        end
        %% -----------------------------------------------------------------
        
        function cfg = getPreloadedCfg( obj, pcFolder, cfgFolder )
            obj.loadPreloadedConfigs( pcFolder );
            pc = obj.preloadedConfigs(pcFolder);
            cfg = [];
            if pc.isKey( cfgFolder )
                cfg = pc(cfgFolder);
            end
        end
        %% -----------------------------------------------------------------
        
        function procFileExt = getProcFileExt( obj )
            procFileExt = ['.' obj.procName '.mat'];
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        process( obj, inputFileName )
    end
    methods (Abstract, Access = protected)
        outputDeps = getInternOutputDependencies( obj )
        out = getOutput( obj )
    end
    
end

        