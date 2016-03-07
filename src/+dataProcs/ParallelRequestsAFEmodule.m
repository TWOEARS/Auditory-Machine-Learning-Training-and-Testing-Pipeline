classdef ParallelRequestsAFEmodule < core.IdProcInterface
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        individualAfeProcs;
        newAfeProc;
        fs;
        afeRequests;
        outputWavFileName;
        indFile;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = ParallelRequestsAFEmodule( fs, afeRequests )
            obj = obj@core.IdProcInterface();
            for ii = 1:length( afeRequests )
                obj.individualAfeProcs{ii} = dataProcs.AuditoryFEmodule( fs, afeRequests(ii) );
            end
            obj.afeRequests = afeRequests;
            obj.fs = fs;
        end
        %% ----------------------------------------------------------------

        function process( obj, inFileName )
            [p,wavFileName,~] = fileparts( inFileName );
            [~,wavFileName,~] = fileparts( wavFileName );
            soundDir = fileparts( p );
            wavFileName = fullfile( soundDir, wavFileName );
            ownCfg = obj.getOutputDependencies();
            newAfeRequests = {};
            newAfeRequestsIdx = [];
            for ii = 1 : numel( obj.individualAfeProcs )
                obj.individualAfeProcs{ii}.setExternOutputDependencies( ownCfg.extern );
                afePartProcessed = obj.individualAfeProcs{ii}.hasFileAlreadyBeenProcessed( wavFileName );
                if ~afePartProcessed
                    newAfeRequests(end+1) = obj.afeRequests(ii);
                    newAfeRequestsIdx(end+1) = ii;
                end
            end
            obj.outputWavFileName = wavFileName;
            if ~isempty( newAfeRequestsIdx )
                obj.newAfeProc = dataProcs.AuditoryFEmodule( obj.fs, newAfeRequests );
                obj.newAfeProc.setExternOutputDependencies( ownCfg.extern );
                obj.newAfeProc.process( inFileName );
                for jj = 1 : numel( newAfeRequestsIdx )
                    ii = newAfeRequestsIdx(jj);
                    obj.individualAfeProcs{ii}.output = obj.newAfeProc.output;
                    obj.individualAfeProcs{ii}.output.afeData = ...
                        containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
                    obj.individualAfeProcs{ii}.output.afeData(1) = ...
                        obj.newAfeProc.output.afeData(jj);
                    obj.individualAfeProcs{ii}.saveOutput( wavFileName );
                end
            end
            fprintf( '*\n' );
            for ii = 1 : numel( obj.individualAfeProcs )
                obj.indFile{ii} = ...
                    obj.individualAfeProcs{ii}.getOutputFileName( wavFileName ) ;
            end
        end
        %% ----------------------------------------------------------------
        
        function afeDummy = makeDummyData ( obj )
            dummyAfeProc = dataProcs.AuditoryFEmodule( obj.fs, obj.afeRequests );
            afeDummy.afeData = dummyAfeProc.makeAFEdata( rand( 4100, 2 ) );
            afeDummy.onOffsOut = zeros(0,2);
            afeDummy.annotsOut = [];
        end
        %% ----------------------------------------------------------------
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            for ii = 1 : numel( obj.individualAfeProcs )
                outputDeps.(['afeDep' num2str(ii)]) = ...
                    obj.individualAfeProcs{ii}.getInternOutputDependencies.afeParams;
            end
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
