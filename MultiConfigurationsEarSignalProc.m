classdef MultiConfigurationsEarSignalProc < IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (Access = private)
        sceneConfigurations;
        binauralSim;
        singleConfFiles;
        singleConfs;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsEarSignalProc( binauralSim )
            obj = obj@IdProcInterface();
            if ~isa( binauralSim, 'IdProcInterface' )
                error( 'binauralSim must implement IdProcInterface.' );
            end
            obj.binauralSim = binauralSim;
            obj.sceneConfigurations = SceneConfiguration.empty;
        end
        %% ----------------------------------------------------------------
        
        function setSceneConfig( obj, sceneConfig )
            obj.sceneConfigurations = sceneConfig;
        end
        %% ----------------------------------------------------------------

        function process( obj, inputFileName )
            obj.makeEarsignalsAndLabels( inputFileName );
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            for ii = 1 : length( obj.sceneConfigurations )
                outDepName = sprintf( 'sceneConfig%d', ii );
                obj.binauralSim.setSceneConfig( obj.sceneConfigurations(ii) );
                outputDeps.(outDepName) = obj.binauralSim.getInternOutputDependencies;
            end
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.singleConfFiles = obj.singleConfFiles;
            out.singleConfs = obj.singleConfs;
        end
        %% ----------------------------------------------------------------
        
        function makeEarsignalsAndLabels( obj, wavFileName )
            obj.singleConfFiles = {};
            obj.singleConfs = [];
            for ii = 1 : numel( obj.sceneConfigurations )
                sceneConf = obj.sceneConfigurations(ii);
                obj.binauralSim.setSceneConfig( sceneConf );
                if ~obj.binauralSim.hasFileAlreadyBeenProcessed( wavFileName )
                    obj.binauralSim.process( wavFileName );
                    obj.binauralSim.saveOutput( wavFileName );
                end
                obj.singleConfFiles{ii} = obj.binauralSim.getOutputFileName( wavFileName );
                obj.singleConfs{ii} = obj.binauralSim.getInternOutputDependencies;
%                 soFarEarSlength = length( obj.earSout ) / obj.getDataFs;
%                 obj.onOffsOut = [obj.onOffsOut; soFarEarSlength + binauralOut.onOffsOut];
%                 obj.earSout = [obj.earSout; binauralOut.earSout];
                fprintf( '.' );
            end
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end
