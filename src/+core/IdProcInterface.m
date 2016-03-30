classdef (Abstract) IdProcInterface < handle
    %% data file processor
    %
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        procName;
        cacheSystemDir;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected, Transient = true)
        cacheDirectory;
        soundDbBaseDir;
        inputProc;
        idData;
        lastFolder;
        lastConfig;
        outFileSema;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function delete( obj )
            removefilesemaphore( obj.outFileSema );
            obj.saveCacheDirectory();
        end
        %% -------------------------------------------------------------------------------
        
        function saveCacheDirectory( obj )
            obj.cacheDirectory.saveCacheDirectory();
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
            obj.lastFolder = '';
            obj.lastConfig = [];
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
                out = obj.saveOutput( wavFilepath );
            elseif nargout > 0
                out = obj.loadProcessedData( wavFilepath );
            end
        end
        %% -------------------------------------------------------------------------------

        function out = loadProcessedData( obj, wavFilepath )
            outFilepath = obj.getOutputFilepath( wavFilepath );
            obj.outFileSema = setfilesemaphore( outFilepath );
            out = load( obj.getOutputFilepath( wavFilepath ) );
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------
        
        function inData = loadInputData( obj, wavFilepath )
            inData = obj.inputProc.loadProcessedData( wavFilepath );
        end
        %% -------------------------------------------------------------------------------

        function outFilepath = getOutputFilepath( obj, wavFilepath )
            fileName = wavFilepath(numel(obj.soundDbBaseDir)+1:end);
            fileName = strrep( fileName, '/', '.' );
            fileName = strrep( fileName, '\', '.' );
            fileName = strrep( fileName, ':', '.' );
            fileName = strrep( fileName, ' ', '.' );
            outFilepath = ...
                fullfile( obj.getCurrentFolder(), [fileName obj.getProcFileExt] );
        end
        %% -------------------------------------------------------------------------------

        function fileProcessed = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            if isempty( wavFilepath ), fileProcessed = false; return; end
            fileProcessed = exist( obj.getOutputFilepath( wavFilepath ), 'file' );
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

        function setCacheSystemDir( obj, cacheSystemDir, soundDbBaseDir )
            if exist( cacheSystemDir, 'dir' )
                obj.cacheSystemDir = fullfile( cacheSystemDir, obj.procName );
                obj.cacheDirectory.setCacheTopDir( obj.cacheSystemDir, true );
            else
                error( 'cannot find directory "%s": does it exist?', cacheSystemDir ); 
            end
            if isempty( soundDbBaseDir ) 
                obj.soundDbBaseDir = soundDbBaseDir;
            elseif exist( soundDbBaseDir, 'dir' )
                obj.soundDbBaseDir = fullfile( soundDbBaseDir, filesep );
            else
                error( 'cannot find directory "%s": does it exist?', soundDbBaseDir ); 
            end
        end
        %% -------------------------------------------------------------------------------
        
        function currentFolder = getCurrentFolder( obj )
            currentConfig = obj.getOutputDependencies();
            if ~isempty( obj.lastFolder ) ...
                    && isequalDeepCompare( currentConfig, obj.lastConfig )
                currentFolder = obj.lastFolder;
                return;
            end
            obj.cacheDirectory.loadCacheDirectory();
            currentFolder = obj.cacheDirectory.getCacheFilepath( currentConfig, true );
            obj.lastFolder = currentFolder;
            obj.lastConfig = currentConfig;
        end
        %% -------------------------------------------------------------------------------
        
        function setInputProc( obj, inputProc )
            if ~isempty( inputProc ) && ~isa( inputProc, 'core.IdProcInterface' )
                error( 'inputProc must be of type core.IdProcInterface' );
            end
            obj.inputProc = inputProc;
        end
        %% -------------------------------------------------------------------------------
        
        % this can be overridden in subclasses
        function outObj = getOutputObject( obj )
            outObj = obj;
        end
        %% -------------------------------------------------------------------------------
        
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
            obj.cacheDirectory = core.IdCacheDirectory();
        end
        %% -------------------------------------------------------------------------------
        
        function out = save( obj, wavFilepath, data )
            out = data;
            if isempty( wavFilepath ), return; end
            outFilepath = obj.getOutputFilepath( wavFilepath );
            obj.outFileSema = setfilesemaphore( outFilepath );
            save( outFilepath, '-struct', 'out' );
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------

        function procFileExt = getProcFileExt( obj )
            procFileExt = ['.' obj.procName '.mat'];
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        process( obj, wavFilepath )
    end
    methods (Abstract, Access = protected)
        outputDeps = getInternOutputDependencies( obj )
        out = getOutput( obj )
    end
    
end

        