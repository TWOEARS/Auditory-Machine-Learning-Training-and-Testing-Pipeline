classdef Base < core.IdProcInterface
    % Base Abstract base class for labeling blocks
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        y;
        inDatPath;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        outputDeps = getLabelInternOutputDependencies( obj )
        y = label( obj, annotations )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = Base()
            obj = obj@core.IdProcInterface();
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            in = obj.loadInputData( wavFilepath );
            obj.inDatPath = obj.inputProc.getOutputFilepath( wavFilepath );
            obj.y = [];
            for blockAnnotation = in.blockAnnotations
                obj.y(end+1,:) = obj.label( blockAnnotation{1} );
                fprintf( '.' );
            end
        end
        %% -------------------------------------------------------------------------------

        % override of dataProcs.IdProcInterface's method
        function out = loadProcessedData( obj, wavFilepath )
            tmpOut = loadProcessedData@core.IdProcInterface( obj, wavFilepath );
            obj.inDatPath = tmpOut.inDatPath;
            try
                out = obj.getOutput;
            catch err
                if strcmp( 'LCB.FileCorrupt', err.msgIdent )
                    err( '%s \n%s corrupt -- delete and restart.', ...
                                          err.msg, obj.getOutputFilepath( wavFilepath ) );
                else
                    rethrow( err );
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.v = 1;
            outputDeps.labelProc = obj.getLabelInternOutputDependencies();
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( obj )
            if ~exist( obj.inDatPath, 'file' )
                error( 'LCB.FileCorrupt', '%s not found.', obj.inDatPath );
            end
            inDat = load( obj.inDatPath );
            out.x = inDat.x;
            out.a = inDat.blockAnnotations;
            out.y = obj.y;
        end
        %% -------------------------------------------------------------------------------
        
        % override of dataProcs.IdProcInterface's method
        function save( obj, wavFilepath, ~ )
            out.y = obj.y;
            out.inDatPath = obj.inDatPath;
            save@core.IdProcInterface( obj, wavFilepath, out ); 
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

