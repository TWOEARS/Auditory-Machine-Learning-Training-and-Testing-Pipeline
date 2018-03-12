classdef (Abstract) IdProcInterface < handle
    %% data file processor
    %
    
    %% -----------------------------------------------------------------------------------
    properties
        procName;
        cacheSystemDir;
        nPathLevelsForCacheName = 3;
        procCacheFolderNames = '';
        procCacheFolderNames_intern = '';
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected, Transient = true)
        cacheDirectory;
        inputProc;
        idData;
        lastFolder = {};
        lastConfig = {};
        outFileSema;
        sceneId = 1;
        foldId = 1;
        saveImmediately = true;
        setLoadSemaphore = true;
        secondCfgCheck = true
        saveSerialized = false;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function delete( obj )
            removefilesemaphore( obj.outFileSema );
            if ~isempty( obj.cacheDirectory )
                obj.saveCacheDirectory();
            end
        end
        %% -------------------------------------------------------------------------------
        
        function set.procCacheFolderNames( obj, newPCFN )
            newPCFN = obj.overridableSetPCFN( newPCFN );
            obj.procCacheFolderNames = newPCFN;
        end
        %% ----------------------------------------------------------------
        
        function set.sceneId( obj, newScnId )
            newScnId = obj.overridableSetScnId( newScnId );
            obj.sceneId = newScnId;
        end
        %% ----------------------------------------------------------------
        
        function set.foldId( obj, newFoldId )
            newFoldId = obj.overridableSetFoldId( newFoldId );
            obj.foldId = newFoldId;
        end
        %% ----------------------------------------------------------------
        
        function saveCacheDirectory( obj )
            obj.cacheDirectory.saveCacheDirectory();
        end
        %% -------------------------------------------------------------------------------
        
        function loadCacheDirectory( obj )
            obj.cacheDirectory.loadCacheDirectory();
        end
        %% -------------------------------------------------------------------------------

        function getSingleProcessCacheAccess( obj )
            obj.cacheDirectory.getSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------
        
        function releaseSingleProcessCacheAccess( obj )
            obj.cacheDirectory.releaseSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------

        function connectIdData( obj, idData )
            obj.idData = idData;
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj )
            obj.lastFolder = {};
            obj.lastConfig = {};
            obj.sceneId = 1;
            obj.foldId = 1;
            obj.setLoadSemaphore = true;
            obj.secondCfgCheck = true;
        end
        %% -------------------------------------------------------------------------------
        
        function out = saveOutput( obj, wavFilepath )
            out = obj.getOutput();
            obj.save( wavFilepath, out );
        end
        %% -------------------------------------------------------------------------------
        
        function out = processSaveAndGetOutput( obj, wavFilepath )
            if ~obj.hasFileAlreadyBeenProcessed( wavFilepath )
                obj.process( wavFilepath );
                if nargout > 0
                    out = obj.saveOutput( wavFilepath );
                else
                    obj.saveOutput( wavFilepath );
                end
            elseif nargout > 0
                out = obj.loadProcessedData( wavFilepath );
            end
        end
        %% -------------------------------------------------------------------------------

        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            outFilepath = obj.getOutputFilepath( wavFilepath );
            if obj.setLoadSemaphore
                obj.outFileSema = setfilesemaphore( outFilepath, 'semaphoreOldTime', 30 );
            end
            if obj.saveSerialized
                out = load( outFilepath );
                if isfield( out, 'outSerialized' )
                    out = getArrayFromByteStream( out.outSerialized );
                end
            else
                out = load( outFilepath, varargin{:} );
            end
            if obj.setLoadSemaphore
                removefilesemaphore( obj.outFileSema );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function [inData, inDataFilepath] = loadInputData( obj, wavFilepath, varargin )
            obj.inputProc.sceneId = obj.sceneId;
            obj.inputProc.foldId = obj.foldId;
            obj.inputProc.setLoadSemaphore = obj.setLoadSemaphore;
            obj.inputProc.secondCfgCheck = obj.secondCfgCheck;
            [inData, inDataFilepath] = ...
                              obj.inputProc.loadProcessedData( wavFilepath, varargin{:} );
        end
        %% -------------------------------------------------------------------------------

        function outFilepath = getOutputFilepath( obj, wavFilepath )
            filepath = '';
            for ii = 1 : obj.nPathLevelsForCacheName
                [wavFilepath, filepathPart, ext] = fileparts( wavFilepath );
                filepath = [filepathPart ext '.' filepath];
            end
            filepath = filepath(1:end-1);
            filepath = strrep( filepath, '/', '.' );
            filepath = strrep( filepath, '\', '.' );
            filepath = strrep( filepath, ':', '.' );
            filepath = strrep( filepath, ' ', '.' );
            outFilepath = ...
                fullfile( obj.getCurrentFolder(), [filepath obj.getProcFileExt] );
        end
        %% -------------------------------------------------------------------------------

        function [fileProcessed,cacheDir] = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            if isempty( wavFilepath ), fileProcessed = false; return; end
            cacheFile = obj.getOutputFilepath( wavFilepath );
            if obj.forceCacheRewrite
                fileProcessed = false;
            else
                fileProcessed = exist( cacheFile, 'file' );
            end
            if nargout > 1
                cacheDir = fileparts( cacheFile );
            end
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getOutputDependencies( obj )
            outputDeps = obj.getInternOutputDependencies();
            if ~isa( outputDeps, 'struct' )
                error( 'getInternOutputDependencies must combine values in a struct.' );
            end
            if isfield( outputDeps, 'preceding' )
                error( 'Intern output dependencies must not contain field named "preceding"' );
            end
            if ~isempty( obj.inputProc )
                outputDeps.preceding = obj.inputProc.getOutputDependencies();
            end
        end
        %% -------------------------------------------------------------------------------

        function setCacheSystemDir( obj, cacheSystemDir, nPathLevelsForCacheName )
            if exist( cacheSystemDir, 'dir' )
                obj.cacheSystemDir = fullfile( cacheSystemDir, obj.procName );
                obj.cacheDirectory.setCacheTopDir( obj.cacheSystemDir, true );
            else
                error( 'cannot find directory "%s": does it exist?', cacheSystemDir ); 
            end
            if exist( 'nPathLevelsForCacheName', 'var' ) 
                obj.nPathLevelsForCacheName = nPathLevelsForCacheName;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function currentFolder = getCurrentFolder( obj )
            currentConfig = obj.getOutputDependencies();
            if size( obj.lastFolder, 1 ) >= obj.sceneId ...
                    && size( obj.lastFolder, 2 ) >= obj.foldId ...
                    && ~isempty( obj.lastFolder{obj.sceneId,obj.foldId} ) 
                if ~obj.secondCfgCheck ...
                        || isequalDeepCompare( currentConfig, obj.lastConfig{obj.sceneId,obj.foldId} )
                    currentFolder = obj.lastFolder{obj.sceneId,obj.foldId};
                    return;
                end
            end
            obj.cacheDirectory.loadCacheDirectory();
            newFolderName = ['.' obj.procCacheFolderNames ...
                             '_' obj.procCacheFolderNames_intern ...
                             '_scene' num2str( obj.sceneId ) ...
                             '_fold' num2str( obj.foldId )];
            currentFolder = obj.cacheDirectory.getCacheFilepath( currentConfig, true, newFolderName );
            if obj.saveImmediately
                obj.cacheDirectory.saveCacheDirectory();
            end
            obj.lastFolder{obj.sceneId,obj.foldId} = currentFolder;
            obj.lastConfig{obj.sceneId,obj.foldId} = currentConfig;
        end
        %% -------------------------------------------------------------------------------
        
        function setInputProc( obj, inputProc )
            if ~isempty( inputProc ) && ~isa( inputProc, 'Core.IdProcInterface' )
                error( 'inputProc must be of type Core.IdProcInterface' );
            end
            obj.inputProc = inputProc;
        end
        %% -------------------------------------------------------------------------------
        
        function setDirectCacheSave( obj, saveImmediately )
            obj.saveImmediately = saveImmediately;
        end            
        %% -------------------------------------------------------------------------------
        
        % this can be overridden in subclasses
        function outObj = getOutputObject( obj )
            outObj = obj;
        end
        %% -------------------------------------------------------------------------------
        
        function save( obj, wavFilepath, out ) %#ok<INUSD>
            if isempty( wavFilepath ), return; end
            outFilepath = obj.getOutputFilepath( wavFilepath );
            obj.outFileSema = setfilesemaphore( outFilepath, 'semaphoreOldTime', 30 );
            if obj.saveSerialized
                outSerialized = getByteStreamFromArray( out ); %#ok<NASGU>
                save( outFilepath, 'outSerialized', '-v6' );
            else
                save( outFilepath, '-struct', 'out', '-v6' );
            end
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function obj = IdProcInterface( procName, saveSerialized )
            if nargin < 1 || isempty( procName )
                classInfo = metaclass( obj );
                [classname1, classname2] = strtok( classInfo.Name, '.' );
                if isempty( classname2 ), obj.procName = classname1;
                else obj.procName = classname2(2:end); end
            else
                obj.procName = procName;
            end
            obj.cacheDirectory = Core.IdCacheDirectory();
            if nargin < 2 || isempty( saveSerialized )
                saveSerialized = false;
            end
            obj.saveSerialized = saveSerialized;
        end
        %% -------------------------------------------------------------------------------

        function procFileExt = getProcFileExt( obj )
            procFileExt = '.mat';
        end
        %% -------------------------------------------------------------------------------
        
        function newPCFN = overridableSetPCFN( obj, newPCFN )
            assert( ischar( newPCFN ) );
        end
        %% ----------------------------------------------------------------
        
        function newScnId = overridableSetScnId( obj, newScnId )
            assert( isnumeric( newScnId ) && numel( newScnId ) == 1 );
        end
        %% ----------------------------------------------------------------
        
        function newFoldId = overridableSetFoldId( obj, newFoldId )
            assert( isnumeric( newFoldId ) && numel( newFoldId ) == 1 );
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Static)

        function b = forceCacheRewrite( newValue )
            persistent fcrw;
            if isempty( fcrw )
                fcrw = false;
            end
            if nargin > 0 
                fcrw = newValue;
            else
                b = fcrw;
            end
        end
        %% ----------------------------------------------------------------

    end
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        process( obj, wavFilepath )
    end
    methods (Abstract, Access = protected)
        outputDeps = getInternOutputDependencies( obj )
        out = getOutput( obj, varargin )
    end
    
end

        