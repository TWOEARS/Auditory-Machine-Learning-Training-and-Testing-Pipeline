classdef MultiConfigurationsFeatureProc < core.IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        featProc;
        singleConfFiles;
        singleConfs;
        precollected;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiConfigurationsFeatureProc( featProc )
            obj = obj@core.IdProcInterface();
            if ~isa( featProc, 'core.IdProcInterface' )
                error( 'featProc must implement core.IdProcInterface.' );
            end
            obj.featProc = featProc;
            obj.precollected = containers.Map('KeyType','char','ValueType','any');
        end
        %% ----------------------------------------------------------------

        function setCacheSystemDir( obj, cacheSystemDir, soundDbBaseDir )
            setCacheSystemDir@core.IdProcInterface( obj, cacheSystemDir, soundDbBaseDir );
            obj.featProc.setCacheSystemDir( cacheSystemDir, soundDbBaseDir );
        end
        %% -----------------------------------------------------------------
        
        function saveCacheDirectory( obj )
            saveCacheDirectory@core.IdProcInterface( obj );
            obj.featProc.saveCacheDirectory();
        end
        %% -----------------------------------------------------------------        

        function getSingleProcessCacheAccess( obj )
            getSingleProcessCacheAccess@core.IdProcInterface( obj );
            obj.featProc.getSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------
        
        function releaseSingleProcessCacheAccess( obj )
            releaseSingleProcessCacheAccess@core.IdProcInterface( obj );
            obj.featProc.releaseSingleProcessCacheAccess();
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            obj.makeFeatures( wavFilepath );
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.featDeps = obj.featProc.getInternOutputDependencies;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.singleConfFiles = obj.singleConfFiles;
            out.singleConfs = obj.singleConfs;
        end
        %% ----------------------------------------------------------------
        
        function makeFeatures( obj, wavFilepath )
            precoll = [];
            if obj.precollected.isKey( wavFilepath )
                precoll = obj.precollected(wavFilepath);
            end
            obj.singleConfFiles = {};
            obj.singleConfs = [];
            multiCfg = obj.getOutputDependencies();
            scFieldNames = fieldnames( multiCfg.preceding.preceding );
            for ii = 1 : numel( scFieldNames )
                if ~isempty( precoll ) && isfield( precoll, scFieldNames{ii} )
                    obj.singleConfFiles{ii} = precoll.(scFieldNames{ii}).fname;
                    obj.singleConfs{ii} = precoll.(scFieldNames{ii}).cfg;
                else
%                     conf = [];
%                     conf.afeParams = multiCfg.preceding.afeDeps;
%                     conf.extern = multiCfg.preceding.preceding.(scFieldNames{ii});
%                     obj.featProc.setExternOutputDependencies( conf );
                    if ~obj.featProc.hasFileAlreadyBeenProcessed( wavFilepath )
                        in = obj.loadInputData( wavFilepath );
                        if ~exist( in.singleConfFiles{ii}, 'file' )
                            error( '%s not found. \n%s corrupt -- delete and restart.', ...
                                in.singleConfFiles{ii}, ...
                                obj.inputProc.getOutputFilepath( wavFilepath ) );
                        end
                        obj.featProc.process( wavFilepath );
                        obj.featProc.saveOutput( wavFilepath );
                    end
                    obj.singleConfFiles{ii} = obj.featProc.getOutputFileName( wavFilepath );
                    obj.singleConfs{ii} = obj.featProc.getOutputDependencies;
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
%             scFieldNames = fieldnames( multiCfg.extern.extern );
%             fprintf( '#' );
%             for ii = 1 : numel( scFieldNames )
%                 conf = [];
%                 conf.afeParams = multiCfg.extern.afeDeps;
%                 conf.extern = multiCfg.extern.extern.(scFieldNames{ii});
%                 obj.featProc.setExternOutputDependencies( conf );
%                 if ~obj.featProc.hasFileAlreadyBeenProcessed( wavFileName )
%                     precProcFileNeeded = true;
%                     break;
%                 end
%                 precoll.(scFieldNames{ii}).fname = obj.featProc.getOutputFileName( wavFileName );
%                 precoll.(scFieldNames{ii}).cfg = obj.featProc.getOutputDependencies;
%                 fprintf( '.' );
%             end
%             obj.precollected(wavFileName) = precoll;
%             fprintf( '\n' );
%         end
%         %% -----------------------------------------------------------------
        
    end
    
end
