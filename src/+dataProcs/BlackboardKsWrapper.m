classdef BlackboardKsWrapper < Core.IdProcInterface
    % Abstract base class for wrapping KS into an emulated blackboard
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        ks;
        bbs;
        afeDataIndexOffset;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        preproc( obj )
        postproc( obj )
        outputDeps = getKsInternOutputDependencies( obj )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = BlackboardKsWrapper( ks, afeDataIndexOffset )
            obj = obj@Core.IdProcInterface();
            obj.ks = ks;
            obj.bbs = BlackboardSystem( false );
            obj.afeDataIndexOffset = afeDataIndexOffset;
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            inData = obj.loadInputData( wavFilepath );
            for afeBlock = inData.afeBlocks
                afeData = afeBlock{1};
                for ii = 1 : numel( obj.ks.reqHashs )
                    obj.bbs.blackboard.addSignal( ...
                              obj.ks.reqhashs{ii}, afeData(ii + obj.afeDataIndexOffset) );
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function out = loadProcessedData( obj, wavFilepath )
            out = loadProcessedData@Core.IdProcInterface( obj, wavFilepath );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.v = 1;
            outputDeps.ksProc = obj.getKsInternOutputDependencies();
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( obj )
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function save( obj, wavFilepath, out )
            save@Core.IdProcInterface( obj, wavFilepath, out ); 
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

