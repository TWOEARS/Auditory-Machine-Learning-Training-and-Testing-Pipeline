classdef ParallelRequestsAFEmodule < core.IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        individualAfeProcs;
        fs;
        afeRequests;
        indFile;
        currentNewAfeRequestsIdx;
        currentNewAfeProc;
        prAfeDepProducer;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = ParallelRequestsAFEmodule( fs, afeRequests )
            obj = obj@core.IdProcInterface();
            for ii = 1:length( afeRequests )
                obj.individualAfeProcs{ii} = ...
                                        dataProcs.AuditoryFEmodule( fs, afeRequests(ii) );
            end
            for ii = 2:length( afeRequests )
                obj.individualAfeProcs{ii}.cacheDirectory = ...
                                                 obj.individualAfeProcs{1}.cacheDirectory;
            end
            obj.afeRequests = afeRequests;
            obj.fs = fs;
            obj.prAfeDepProducer = dataProcs.AuditoryFEmodule( fs, afeRequests );
        end
        %% ----------------------------------------------------------------

        % override of core.IdProcInterface's method
        function setCacheSystemDir( obj, cacheSystemDir, soundDbBaseDir )
            setCacheSystemDir@core.IdProcInterface( obj, cacheSystemDir, soundDbBaseDir );
            for ii = 1 : numel( obj.individualAfeProcs )
                obj.individualAfeProcs{ii}.setCacheSystemDir( cacheSystemDir, soundDbBaseDir );
            end
        end
        %% -----------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function saveCacheDirectory( obj )
            saveCacheDirectory@core.IdProcInterface( obj );
            for ii = 1 : numel( obj.individualAfeProcs )
                obj.individualAfeProcs{ii}.saveCacheDirectory();
            end
        end
        %% -----------------------------------------------------------------        

        % override of core.IdProcInterface's method
        function getSingleProcessCacheAccess( obj )
            getSingleProcessCacheAccess@core.IdProcInterface( obj );
%             for ii = 1 : numel( obj.individualAfeProcs )
                obj.individualAfeProcs{1}.getSingleProcessCacheAccess();
%             end
        end
        %% -------------------------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function releaseSingleProcessCacheAccess( obj )
            releaseSingleProcessCacheAccess@core.IdProcInterface( obj );
%             for ii = 1 : numel( obj.individualAfeProcs )
                obj.individualAfeProcs{1}.releaseSingleProcessCacheAccess();
%             end
        end
        %% -------------------------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function setInputProc( obj, inputProc )
            setInputProc@core.IdProcInterface( obj, inputProc );
            for ii = 1 : numel( obj.individualAfeProcs )
                obj.individualAfeProcs{ii}.setInputProc( inputProc );
            end
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            newAfeRequests = {};
            newAfeRequestsIdx = [];
            for ii = 1 : numel( obj.individualAfeProcs )
                afePartProcessed = ...
                    obj.individualAfeProcs{ii}.hasFileAlreadyBeenProcessed( wavFilepath );
                if ~afePartProcessed
                    newAfeRequests(end+1) = obj.afeRequests(ii);
                    newAfeRequestsIdx(end+1) = ii;
                end
            end
            if ~isempty( newAfeRequestsIdx )
                if ~isequal( newAfeRequestsIdx, obj.currentNewAfeRequestsIdx )
                    obj.currentNewAfeProc = ...
                                     dataProcs.AuditoryFEmodule( obj.fs, newAfeRequests );
                    obj.currentNewAfeProc.setInputProc( obj.inputProc );
                    obj.currentNewAfeProc.cacheSystemDir = obj.cacheSystemDir;
                    obj.currentNewAfeProc.soundDbBaseDir = obj.soundDbBaseDir;
                    obj.currentNewAfeRequestsIdx = newAfeRequestsIdx;
                end
                obj.currentNewAfeProc.process( wavFilepath );
                for jj = 1 : numel( newAfeRequestsIdx )
                    ii = newAfeRequestsIdx(jj);
                    obj.individualAfeProcs{ii}.output = obj.currentNewAfeProc.output;
                    obj.individualAfeProcs{ii}.output.afeData = ...
                                 containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
                    obj.individualAfeProcs{ii}.output.afeData(1) = ...
                                                 obj.currentNewAfeProc.output.afeData(jj);
                    obj.individualAfeProcs{ii}.saveOutput( wavFilepath );
                end
            end
            for ii = 1 : numel( obj.individualAfeProcs )
                obj.indFile{ii} = ...
                              obj.individualAfeProcs{ii}.getOutputFilepath( wavFilepath );
            end
        end
        %% ----------------------------------------------------------------
        
        function afeDummy = makeDummyData ( obj )
            afeDummy.afeData = obj.prAfeDepProducer.makeAFEdata( rand( obj.fs/10, 2 ) );
            afeDummy.onOffsOut = zeros(0,2);
            afeDummy.annotsOut = [];
        end
        %% ----------------------------------------------------------------
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            afeDeps = obj.prAfeDepProducer.getInternOutputDependencies.afeParams;
            outputDeps.afeParams = afeDeps;
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.indFile = obj.indFile;
        end
        %% ----------------------------------------------------------------
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end
