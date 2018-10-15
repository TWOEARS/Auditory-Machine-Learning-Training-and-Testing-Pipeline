classdef MultiExecuteLabeler < DataProcs.IdProcWrapper
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        individualLabelers;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiExecuteLabeler( individualLabelers )
            obj = obj@DataProcs.IdProcWrapper( individualLabelers, false );
            obj.individualLabelers = individualLabelers;
        end
        %% ----------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [fileProcessed,cacheDirs] = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            fileProcessed = true;
            if nargout > 1
                cacheDirs = cell( numel( obj.individualLabelers ), 1 );
            end
            for ii = 1 : numel( obj.individualLabelers )
                if nargout > 1
                    [processed,cacheDirs{ii}] = obj.wrappedProcs{ii}.hasFileAlreadyBeenProcessed( wavFilepath );
                else
                    processed = obj.wrappedProcs{ii}.hasFileAlreadyBeenProcessed( wavFilepath );
                end
                fileProcessed = fileProcessed && processed;
                % not stopping early because hasFileAlreadyBeenProcessed triggers cache
                % directory creation
                if processed
                    fprintf( ',' );
                else
                    fprintf( '~' );
                end
                if Core.DataPipeProc.doEarlyHasProcessedStop && ~fileProcessed
                    return;
                end
            end
        end
        %% -------------------------------------------------------------------------------
       
        % override of Core.IdProcInterface's method
        function out = processSaveAndGetOutput( obj, wavFilepath )
            obj.process( wavFilepath );
            out = [];
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            in = obj.individualLabelers{1}.loadInputData( wavFilepath, 'blockAnnotations' );
            for ii = 1 : numel( obj.individualLabelers )
                if ~obj.individualLabelers{ii}.hasFileAlreadyBeenProcessed( wavFilepath )
                    fprintf( '[%s]', obj.individualLabelers{ii}.procName );
                    y = [];
                    ysi = {};
                    for blockAnnotation = in.blockAnnotations'
                        if obj.individualLabelers{ii}.labelBlockSize_auto
                            obj.individualLabelers{ii}.labelBlockSize_s = ...
                                 blockAnnotation.blockOffset - blockAnnotation.blockOnset;
                        end
                        [y(end+1,:),ysi{end+1}] = obj.individualLabelers{ii}.label( ...
                                                                        blockAnnotation ); %#ok<AGROW>
                        if obj.individualLabelers{ii}.labelBlockSize_auto
                            obj.individualLabelers{ii}.labelBlockSize_s = [];
                        end
                    end
                    obj.individualLabelers{ii}.y = y;
                    obj.individualLabelers{ii}.ysi = ysi;
                    obj.individualLabelers{ii}.saveOutput( wavFilepath );
                    fprintf( ':' );
                end
            end
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( ~, ~ ) 
            out = [];
            outFilepath = '';
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function inData = loadInputData( ~, ~, ~ )
            inData = [];
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function outFilepath = getOutputFilepath( ~, ~ )
            outFilepath = [];
        end
        %% -------------------------------------------------------------------------------
       
        % override of Core.IdProcInterface's method
        function currentFolder = getCurrentFolder( obj )
            currentFolder = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function out = save( ~, ~, ~ )
            out = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcWrapper's method
        function setCacheSystemDir( obj, cacheSystemDir, nPathLevelsForCacheName, cacheDirectoryDirSuppl )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.setCacheSystemDir( cacheSystemDir, nPathLevelsForCacheName, cacheDirectoryDirSuppl );
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcWrapper's method
        function loadCacheDirectory( obj )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.loadCacheDirectory();
            end
        end
        %% -----------------------------------------------------------------        

        % override of DataProcs.IdProcWrapper's method
        function getSingleProcessCacheAccess( obj )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.getSingleProcessCacheAccess();
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcWrapper's method
        function releaseSingleProcessCacheAccess( obj )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.releaseSingleProcessCacheAccess();
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of DataProcs.IdProcWrapper's method
        function delete( obj )
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------
    end
        
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.wrapDeps = getInternOutputDependencies@DataProcs.IdProcWrapper( obj );
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj, varargin )
            out = [];
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
