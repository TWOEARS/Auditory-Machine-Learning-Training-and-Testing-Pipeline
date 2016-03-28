classdef MultiSceneCfgsIdProcWrapper < dataProcs.IdProcWrapper
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfigurations;
        sceneProc;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiSceneCfgsIdProcWrapper( sceneProc, wrapProc,...
                                                              multiSceneCfgs )
            obj = obj@dataProcs.IdProcWrapper( wrapProc, true );
            if ~isa( sceneProc, 'core.IdProcInterface' )
                error( 'sceneProc must implement core.IdProcInterface.' );
            end
            obj.sceneProc = sceneProc;
            if nargin < 3, multiSceneCfgs = sceneConfig.SceneConfiguration.empty; end
            obj.sceneConfigurations = multiSceneCfgs;
        end
        %% ----------------------------------------------------------------

        function setSceneConfig( obj, multiSceneCfgs )
            obj.sceneConfigurations = multiSceneCfgs;
        end
        %% ----------------------------------------------------------------

        % override of core.IdProcInterface's method
        function fileProcessed = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            fileProcessed = true;
            for ii = 1 : numel( obj.sceneConfigurations )
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                if ~obj.wrappedProcs{1}.hasFileAlreadyBeenProcessed( wavFilepath )
                    fileProcessed = false; return;
                end
            end
        end
        %% -------------------------------------------------------------------------------
       
        % override of core.IdProcInterface's method
        function out = processSaveAndGetOutput( obj, wavFilepath )
            obj.process( wavFilepath );
            out = obj.saveOutput( wavFilepath );
            if nargout > 0
                out = obj.loadProcessedData( wavFilepath );
            end
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            for ii = 1 : numel( obj.sceneConfigurations )
                fprintf( 'sc%d', ii );
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                obj.wrappedProcs{1}.processSaveAndGetOutput( wavFilepath );
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
        function currentFolder = getCurrentFolder( obj )
            currentFolder = [];
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
                outputDeps.(outDepName) = obj.sceneConfigurations(ii);
            end
            obj.sceneProc.setSceneConfig( [] );
            outputDeps.wrapDeps = getInternOutputDependencies@dataProcs.IdProcWrapper( obj );
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
