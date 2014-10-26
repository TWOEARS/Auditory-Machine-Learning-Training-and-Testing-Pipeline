classdef MultiConfigurationsEarSignalProc < BinSimProcInterface
    
    %% --------------------------------------------------------------------
    properties (Access = private)
        sceneConfigurations;
        binauralSim;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsEarSignalProc( binauralSim )
            obj = obj@BinSimProcInterface();
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

        function fs = getDataFs( obj )
            fs = obj.binauralSim.getDataFs();
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
        
        function makeEarsignalsAndLabels( obj, wavFileName )
            obj.earSout = zeros( 0, 2 );
            obj.onOffsOut = zeros( 0, 2 );
            for ii = 1 : numel( obj.sceneConfigurations )
                sceneConf = obj.sceneConfigurations(ii);
                obj.binauralSim.setSceneConfig( sceneConf );
                binauralOut = obj.binauralSim.processSaveAndGetOutput( wavFileName );
                soFarEarSlength = length( obj.earSout ) / obj.getDataFs;
                obj.onOffsOut = [obj.onOffsOut; soFarEarSlength + binauralOut.onOffsOut];
                obj.earSout = [obj.earSout; binauralOut.earSout];
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
