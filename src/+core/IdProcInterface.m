classdef (Abstract) IdProcInterface < handle
    %% data file processor
    %
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        procName;
        cacheSystemDir;
%         externOutputDeps;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected, Transient = true)
%         configChanged = true;
%         currentFolder = [];
        cacheDirectory;
        soundDbBaseDir;
        inputProc;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function delete( obj )
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
        
        function init( obj )
%             obj.cacheDirectory.loadCacheDirectory();
%             obj.configChanged = true;
%             obj.currentFolder = [];
        end
        %% -------------------------------------------------------------------------------
        
%         function savePlaceholderFile( obj, inFilePath )
%             error('remind me, where is this used?');
%             obj.save( inFilePath, struct('dummy',[]) );
%         end
%         %% -------------------------------------------------------------------------------
        
        function out = saveOutput( obj, wavFilepath )
            out = obj.getOutput();
            obj.save( wavFilepath, out );
        end
        %% -------------------------------------------------------------------------------
        
        function out = processSaveAndGetOutput( obj, wavFilepath )
            if ~obj.hasFileAlreadyBeenProcessed( wavFilepath )
                obj.process( wavFilepath );
                out = obj.saveOutput( wavFilepath );
            else
                out = obj.loadProcessedData( wavFilepath );
            end
        end
        %% -------------------------------------------------------------------------------

        function out = loadProcessedData( obj, wavFilepath )
            out = load( obj.getOutputFilepath( wavFilepath ) );
        end
        %% -------------------------------------------------------------------------------
        
        function inData = loadInputData( obj, wavFilepath, dataLabels )
            if nargin < 3, dataLabels = {}; end
            inFilepath = obj.inputProc.getOutputFilepath( wavFilepath );
            inData = load( inFilepath, dataLabels{:} );
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

        function fileProcessed = hasFileAlreadyBeenProcessed( obj, wavFilepath ) %, checkPrecNeed )
            if isempty( wavFilepath ), fileProcessed = false; return; end
            fileProcessed = exist( obj.getOutputFilepath( wavFilepath ), 'file' );
%             if ~fileProcessed && nargin > 2 && checkPrecNeed
%                 precProcFileNeeded = obj.needsPrecedingProcResult( wavFilepath );
%             else
%                 precProcFileNeeded = false;
%             end
        end
        %% -------------------------------------------------------------------------------

%         function setExternOutputDependencies( obj, externOutputDeps )
%             obj.externOutputDeps = externOutputDeps;
% %             obj.configChanged = true;
%         end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getOutputDependencies( obj )
            outputDeps = obj.getInternOutputDependencies();
            if ~isa( outputDeps, 'struct' )
                error( 'getInternOutputDependencies must combine values in a struct.' );
            end
            if isfield( outputDeps, 'preceding' )
                error( 'Intern output dependencies must not contain field named "preceding"' );
            end
%             if ~isempty( obj.externOutputDeps )
%                 outputDeps.extern = obj.externOutputDeps;
%             end
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
%             if ~isempty( obj.currentFolder ) && ~obj.configChanged
%                 currentFolder = obj.currentFolder;
%                 return;
%             end
            currentConfig = obj.getOutputDependencies();
            obj.cacheDirectory.loadCacheDirectory();
            currentFolder = obj.cacheDirectory.getCacheFilepath( currentConfig, true );
%             obj.currentFolder = currentFolder;
%             obj.configChanged = false;
        end
        %% -------------------------------------------------------------------------------
        
        function setInputProc( obj, inputProc )
            if ~isa( inputProc, 'core.IdProcInterface' )
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
%             obj.externOutputDeps = [];
            obj.cacheDirectory = core.IdCacheDirectory();
        end
        %% -------------------------------------------------------------------------------
        
%         function precProcFileNeeded = needsPrecedingProcResult( obj, wavFileName )
%             precProcFileNeeded = true; % this method is overwritten in Multi... subclasses
%         end
%         %% -------------------------------------------------------------------------------
        
        function out = save( obj, wavFilepath, data )
            out = data;
            if isempty( wavFilepath ), return; end
            save( obj.getOutputFilepath( wavFilepath ), '-struct', 'out' );
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

        