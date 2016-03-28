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
            if ~isa( sceneProc, 'dataProcs.BinSimProcInterface' )
                error( 'sceneProc must implement dataProcs.BinSimProcInterface.' );
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
        
        % override of core.IdProcInterface's method
        function outObj = getOutputObject( obj )
            outObj = obj.wrappedProcs{1};
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
            for ii = 1 : numel( obj.wrappedProcs )
                outDepName = sprintf( 'wrappedDeps%d', ii );
                outputDeps.(outDepName) = obj.wrappedProcs{ii}.getInternOutputDependencies;
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
