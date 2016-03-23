classdef MultiConfigurationsAFEmodule < core.IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        afeProc;
        singleConfFiles;
        singleConfs;
        outputWavFileName;
        precollected;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsAFEmodule( afeProc )
            obj = obj@core.IdProcInterface();
            if ~isa( afeProc, 'core.IdProcInterface' )
                error( 'afeProc must implement core.IdProcInterface.' );
            end
            obj.afeProc = afeProc;
            obj.precollected = containers.Map('KeyType','char','ValueType','any');
        end
        %% ----------------------------------------------------------------

        function setCacheSystemDir( obj, cacheSystemDir, soundDbBaseDir )
            setCacheSystemDir@core.IdProcInterface( obj, cacheSystemDir, soundDbBaseDir );
            obj.afeProc.setCacheSystemDir( cacheSystemDir, soundDbBaseDir );
        end
        %% -----------------------------------------------------------------
        
        function saveCacheDirectory( obj )
            saveCacheDirectory@core.IdProcInterface( obj );
            obj.afeProc.saveCacheDirectory();
        end
        %% -----------------------------------------------------------------        

        function getSingleProcessCacheAccess( obj )
            getSingleProcessCacheAccess@core.IdProcInterface( obj );
            obj.afeProc.getSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------
        
        function releaseSingleProcessCacheAccess( obj )
            releaseSingleProcessCacheAccess@core.IdProcInterface( obj );
            obj.afeProc.releaseSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------

        function process( obj, inputFileName )
            obj.makeAFEdata( inputFileName );
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.afeDeps = obj.afeProc.getInternOutputDependencies;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.singleConfFiles = obj.singleConfFiles;
            out.singleConfs = obj.singleConfs;
            out.wavFileName = obj.outputWavFileName;
        end
        %% ----------------------------------------------------------------
        
        function makeAFEdata( obj, inFileName )
            [p,wavFileName,~] = fileparts( inFileName );
            [~,wavFileName,~] = fileparts( wavFileName );
            soundDir = fileparts( p );
            wavFileName = fullfile( soundDir, wavFileName );
            obj.outputWavFileName = wavFileName;
            precoll = [];
            if obj.precollected.isKey( wavFileName )
                precoll = obj.precollected(wavFileName);
            end
            obj.singleConfFiles = {};
            obj.singleConfs = [];
            multiCfg = obj.getOutputDependencies();
            scFieldNames = fieldnames( multiCfg.extern );
            for ii = 1 : numel( scFieldNames )
                if ~isempty( precoll ) && isfield( precoll, scFieldNames{ii} )
                    obj.singleConfFiles{ii} = precoll.(scFieldNames{ii}).fname;
                    obj.singleConfs{ii} = precoll.(scFieldNames{ii}).cfg;
                else
                    conf = multiCfg.extern.(scFieldNames{ii});
                    obj.afeProc.setExternOutputDependencies( conf );
                    in = load( inFileName );
                    p = fileparts( in.singleScFiles{ii} );
                    obj.afeProc.setCacheSystemDir( p );
                    if ~obj.afeProc.hasFileAlreadyBeenProcessed( wavFileName )
                        if ~exist( in.singleScFiles{ii}, 'file' )
                            error( '%s not found. \n%s corrupt -- delete and restart.', ...
                                in.singleScFiles{ii}, inFileName );
                        end
                        obj.afeProc.process( in.singleScFiles{ii} );
                        obj.afeProc.saveOutput( wavFileName );
                    end
                    obj.singleConfFiles{ii} = obj.afeProc.getOutputFileName( wavFileName );
                    obj.singleConfs{ii} = obj.afeProc.getOutputDependencies;
                end
                fprintf( ';' );
            end
            fprintf( '\n' );
        end
        %% ----------------------------------------------------------------
%         
%         function precProcFileNeeded = needsPrecedingProcResult( obj, wavFileName )
%             precProcFileNeeded = false; 
%             multiCfg = obj.getOutputDependencies();
%             precoll = [];
%             scFieldNames = fieldnames( multiCfg.extern );
%             fprintf( '#' );
%             for ii = 1 : numel( scFieldNames )
%                 conf = multiCfg.extern.(scFieldNames{ii});
%                 obj.afeProc.setExternOutputDependencies( conf );
%                 if ~obj.afeProc.hasFileAlreadyBeenProcessed( wavFileName )
%                     precProcFileNeeded = true;
%                     break;
%                 end
%                 precoll.(scFieldNames{ii}).fname = obj.afeProc.getOutputFileName( wavFileName );
%                 precoll.(scFieldNames{ii}).cfg = obj.afeProc.getOutputDependencies;
%                 fprintf( '.' );
%             end
%             obj.precollected(wavFileName) = precoll;
%             fprintf( '\n' );
%         end
%         %% -----------------------------------------------------------------
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end
