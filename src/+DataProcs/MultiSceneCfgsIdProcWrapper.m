classdef MultiSceneCfgsIdProcWrapper < DataProcs.IdProcWrapper
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfigurations;
        sceneProc;
        wrappedLastConfigs;
        wrappedLastFolders;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiSceneCfgsIdProcWrapper( sceneProc, wrapProc,...
                                                              multiSceneCfgs )
            obj = obj@DataProcs.IdProcWrapper( wrapProc, true );
            if ~isa( sceneProc, 'Core.IdProcInterface' )
                error( 'sceneProc must implement Core.IdProcInterface.' );
            end
            obj.sceneProc = sceneProc;
            if nargin < 3, multiSceneCfgs = SceneConfig.SceneConfiguration.empty; end
            obj.sceneConfigurations = multiSceneCfgs;
        end
        %% ----------------------------------------------------------------

        function setSceneConfig( obj, multiSceneCfgs )
            obj.sceneConfigurations = multiSceneCfgs;
            obj.wrappedLastConfigs = cell( size( obj.sceneConfigurations ) );
            obj.wrappedLastFolders = cell( size( obj.sceneConfigurations ) );
        end
        %% ----------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function fileProcessed = hasFileAlreadyBeenProcessed( obj, wavFilepath )
            fileProcessed = true;
            for ii = 1 : numel( obj.sceneConfigurations )
                obj.wrappedProcs{1}.lastConfig = obj.wrappedLastConfigs{ii};
                obj.wrappedProcs{1}.lastFolder = obj.wrappedLastFolders{ii};
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                processed = obj.wrappedProcs{1}.hasFileAlreadyBeenProcessed( wavFilepath );
                obj.wrappedLastConfigs{ii} = obj.wrappedProcs{1}.lastConfig;
                obj.wrappedLastFolders{ii} = obj.wrappedProcs{1}.lastFolder;
                if ~processed
                    fileProcessed = false; return;
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
            for ii = 1 : numel( obj.sceneConfigurations )
                fprintf( 'sc%d', ii );
                obj.wrappedProcs{1}.lastConfig = obj.wrappedLastConfigs{ii};
                obj.wrappedProcs{1}.lastFolder = obj.wrappedLastFolders{ii};
                obj.sceneProc.setSceneConfig( obj.sceneConfigurations(ii) );
                wrapOut = obj.wrappedProcs{1}.processSaveAndGetOutput( wavFilepath );
                wrapOut.annotations.mcSceneId = ii;
%                wrapOut.annotations.sceneConfig = obj.sceneConfigurations(ii);
%                takes too much memory; is reconstrutible through mcSceneId
                obj.wrappedProcs{1}.save( wavFilepath, wrapOut );
                obj.wrappedLastConfigs{ii} = obj.wrappedProcs{1}.lastConfig;
                obj.wrappedLastFolders{ii} = obj.wrappedProcs{1}.lastFolder;
                fprintf( '#' );
            end
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function out = loadProcessedData( ~, ~ ) 
            out = [];
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

        function out = getOutput( obj )
            out = [];
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
