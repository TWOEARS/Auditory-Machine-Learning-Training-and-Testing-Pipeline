classdef ParallelRequestsAFEmodule < dataProcs.IdProcWrapper
    
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
            for ii = 1:length( afeRequests )
                indProcs{ii} = dataProcs.AuditoryFEmodule( fs, afeRequests(ii) );
            end
            for ii = 2:length( afeRequests )
                indProcs{ii}.cacheDirectory = indProcs{1}.cacheDirectory;
            end
            obj = obj@dataProcs.IdProcWrapper( indProcs, false );
            obj.individualAfeProcs = indProcs;
            obj.afeRequests = afeRequests;
            obj.fs = fs;
            obj.prAfeDepProducer = dataProcs.AuditoryFEmodule( fs, afeRequests );
        end
        %% ----------------------------------------------------------------

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
                    obj.currentNewAfeProc.nPathLevelsForCacheName = obj.nPathLevelsForCacheName;
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

        % override of dataProcs.IdProcWrapper's method
        function outObj = getOutputObject( obj )
            outObj = getOutputObject@core.IdProcInterface( obj );
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        % override of dataProcs.IdProcWrapper's method
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
