classdef MultiSceneCfgsIdProcWrapper < DataProcs.IdProcWrapper
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfigurations;
        sceneProc;
        wavFoldsAssignment;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiSceneCfgsIdProcWrapper( sceneProc, wrapProc,...
                                                    multiSceneCfgs, wavFoldsAssignment )
            obj = obj@DataProcs.IdProcWrapper( wrapProc, true );
            if ~isa( sceneProc, 'Core.IdProcInterface' )
                error( 'sceneProc must implement Core.IdProcInterface.' );
            end
            obj.sceneProc = sceneProc;
            if nargin < 3 || isempty( multiSceneCfgs )
                multiSceneCfgs = SceneConfig.SceneConfiguration.empty; 
            end
            obj.sceneConfigurations = multiSceneCfgs;
            if nargin < 4, wavFoldsAssignment = {}; end
            obj.wavFoldsAssignment = wavFoldsAssignment;
        end
        %% ----------------------------------------------------------------

        function setSceneConfig( obj, multiSceneCfgs )
            obj.sceneConfigurations = multiSceneCfgs;
        end
        %% ----------------------------------------------------------------

        function [foldId,foldIdx] = getCurrentFoldId( obj, wavFilepath )
            if ~isempty( obj.wavFoldsAssignment )
                wfa_idx = strcmp( wavFilepath, obj.wavFoldsAssignment(:,1) );
                foldId = obj.wavFoldsAssignment{wfa_idx,2};
                foldIds = unique( [obj.wavFoldsAssignment{:,2}], 'stable' );
                foldIdx = find( foldIds == foldId );
            else
                foldId = 1;
                foldIdx = 1;
            end
        end
        %% ----------------------------------------------------------------

        function sceneCfg_ii = getCurrentFoldSceneConfig( obj, ii, foldId )
            if ~isempty( obj.wavFoldsAssignment )
                sceneCfg_ii = copy( obj.sceneConfigurations(ii) );
                for ss = 1 : numel( sceneCfg_ii.sources )
                    src_ss_data = sceneCfg_ii.sources(ss).data;
                    if isa( src_ss_data, 'SceneConfig.MultiFileListValGen' )
                        sceneCfg_ii.sources(ss).data = src_ss_data.val{foldId};
                    end
                end
            else
                sceneCfg_ii = obj.sceneConfigurations(ii);
            end
        end
        %% ----------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [fileProcessed,cacheDirs] = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            fileProcessed = true;
            if nargout > 1
                cacheDirs = cell( numel( obj.sceneConfigurations ), 1 );
            end
            [foldId,foldIdx] = obj.getCurrentFoldId( wavFilepath );
            obj.wrappedProcs{1}.foldId = foldId;
            for ii = 1 : numel( obj.sceneConfigurations )
                sceneCfg_ii = obj.getCurrentFoldSceneConfig( ii, foldIdx );
                obj.sceneProc.setSceneConfig( sceneCfg_ii );
                obj.wrappedProcs{1}.sceneId = ii;
                if nargout > 1
                    [processed,cacheDirs{ii}] = obj.wrappedProcs{1}.hasFileAlreadyBeenProcessed( wavFilepath );
                else
                    processed = obj.wrappedProcs{1}.hasFileAlreadyBeenProcessed( wavFilepath );
                end
                fileProcessed = fileProcessed && processed;
                % not stopping early because hasFileAlreadyBeenProcessed triggers cache
                % directory creation
                if processed
                    fprintf( '.' );
                else
                    fprintf( '*' );
                end
                if Core.DataPipeProc.doEarlyHasProcessedStop && ~fileProcessed
                    fprintf( '\n' );
                    return;
                end
            end
            fprintf( '\n' );
        end
        %% -------------------------------------------------------------------------------
       
        % override of Core.IdProcInterface's method
        function out = processSaveAndGetOutput( obj, wavFilepath )
            obj.process( wavFilepath );
            out = [];
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            [foldId,foldIdx] = obj.getCurrentFoldId( wavFilepath );
            obj.wrappedProcs{1}.foldId = foldId;
            for ii = 1 : numel( obj.sceneConfigurations )
                sceneCfg_ii = obj.getCurrentFoldSceneConfig( ii, foldIdx );
                obj.sceneProc.setSceneConfig( sceneCfg_ii );
                fprintf( 'sc%d', ii );
                obj.wrappedProcs{1}.sceneId = ii;
                obj.wrappedProcs{1}.processSaveAndGetOutput( wavFilepath );
                fprintf( '#' );
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
        function setCacheSystemDir( obj, cacheSystemDir, nPathLevelsForCacheName )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.setCacheSystemDir( cacheSystemDir, nPathLevelsForCacheName );
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
            for ii = 1 : numel( obj.sceneConfigurations )
                outDepName = sprintf( 'sceneConfig%d', ii );
                outputDeps.(outDepName) = obj.sceneConfigurations(ii);
            end
            obj.sceneProc.setSceneConfig( [] );
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
