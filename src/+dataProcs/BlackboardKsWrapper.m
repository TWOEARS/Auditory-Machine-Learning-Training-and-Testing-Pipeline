classdef BlackboardKsWrapper < Core.IdProcInterface
    % Base Abstract base class for specifying features sets with which features
    % are extracted.
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        ks;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        preproc( obj )
        postproc( obj )
        outputDeps = getKsInternOutputDependencies( obj )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = BlackboardKsWrapper()
            obj = obj@Core.IdProcInterface();
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            inData = obj.loadInputData( wavFilepath );
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

        

