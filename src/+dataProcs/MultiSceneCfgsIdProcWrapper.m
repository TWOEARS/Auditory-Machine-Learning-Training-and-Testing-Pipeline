classdef MultiSceneCfgsIdProcWrapper < core.IdProcInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfigurations;
        sceneProc;
        wrappedProc;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiSceneCfgsIdProcWrapper( sceneProc, wrappedProc,...
                                                              multiSceneCfgs )
            obj = obj@core.IdProcInterface();
            obj.procName = [obj.procName '(' wrappedProc.procName ')'];
            if ~isa( sceneProc, 'dataProcs.BinSimProcInterface' )
                error( 'sceneProc must implement dataProcs.BinSimProcInterface.' );
            end
            if ~isa( wrappedProc, 'core.IdProcInterface' )
                error( 'wrappedProc must implement core.IdProcInterface.' );
            end
            obj.sceneProc = sceneProc;
            obj.wrappedProc = wrappedProc;
            if nargin < 3, multiSceneCfgs = sceneConfig.SceneConfiguration.empty; end
            obj.sceneConfigurations = multiSceneCfgs;
        end
        %% ----------------------------------------------------------------

        % override of core.IdProcInterface's method
        function setCacheSystemDir( obj, cacheSystemDir, soundDbBaseDir )
            setCacheSystemDir@core.IdProcInterface( obj, cacheSystemDir, soundDbBaseDir );
            obj.wrappedProc.setCacheSystemDir( cacheSystemDir, soundDbBaseDir );
        end
        %% -----------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function saveCacheDirectory( obj )
            saveCacheDirectory@core.IdProcInterface( obj );
            obj.wrappedProc.saveCacheDirectory();
        end
        %% -----------------------------------------------------------------        

        % override of core.IdProcInterface's method
        function getSingleProcessCacheAccess( obj )
            getSingleProcessCacheAccess@core.IdProcInterface( obj );
            obj.wrappedProc.getSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function releaseSingleProcessCacheAccess( obj )
            releaseSingleProcessCacheAccess@core.IdProcInterface( obj );
            obj.wrappedProc.releaseSingleProcessCacheAccess();
        end
        %% -----------------------------------------------------------------

        % override of core.IdProcInterface's method
        function connectIdData( obj, idData )
            connectIdData@core.IdProcInterface( obj, idData );
            obj.wrappedProc.connectIdData( idData );
        end
        %% -------------------------------------------------------------------------------
        
        function setSceneConfig( obj, multiSceneCfgs )
            obj.sceneConfigurations = multiSceneCfgs;
        end
        %% ----------------------------------------------------------------

        function process( obj, wavFilepath )
            for ii = 1 : numel( obj.sceneConfigurations )
                fprintf( 'sc%d', ii );
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                if ~obj.wrappedProc.hasFileAlreadyBeenProcessed( wavFilepath )
                    obj.wrappedProc.process( wavFilepath );
                    obj.wrappedProc.saveOutput( wavFilepath );
                end
                fprintf( '#' );
            end
        end
        %% -------------------------------------------------------------------------------

        % override of core.IdProcInterface's method
        function out = loadProcessedData( ~, ~ ) 
            out = [];
        end
        %% -------------------------------------------------------------------------------

        % override of core.IdProcInterface's method
        function inData = loadInputData( ~, ~, ~ )
            inData = [];
        end
        %% -------------------------------------------------------------------------------

        % override of core.IdProcInterface's method
        function outFilepath = getOutputFilepath( ~, ~ )
            outFilepath = [];
        end
        %% -------------------------------------------------------------------------------

        % override of core.IdProcInterface's method
        function fileProcessed = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            fileProcessed = true;
            for ii = 1 : numel( obj.sceneConfigurations )
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                if ~obj.wrappedProc.hasFileAlreadyBeenProcessed( wavFilepath )
                    fileProcessed = false; return;
                end
            end
        end
        %% -------------------------------------------------------------------------------
       
        % override of core.IdProcInterface's method
        function currentFolder = getCurrentFolder( obj )
            currentFolder = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function setInputProc( obj, inputProc )
            setInputProc@core.IdProcInterface( obj, [] );
            obj.wrappedProc.setInputProc( inputProc );
        end
        %% -------------------------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function outObj = getOutputObject( obj )
            outObj = obj.wrappedProc;
        end
        %% -------------------------------------------------------------------------------
    end
        
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        % override of core.IdProcInterface's method
        function out = save( ~, ~, ~ )
            out = [];
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getInternOutputDependencies( obj )
            for ii = 1 : numel( obj.sceneConfigurations )
                outDepName = sprintf( 'sceneConfig%d', ii );
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                outputDeps.(outDepName) = obj.wrappedProc.getInternOutputDependencies;
            end
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out = [];
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
