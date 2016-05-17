classdef Base < Core.IdProcInterface
    % Base Abstract base class for labeling blocks
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        y;
        labelBlockSize_s;
        labelBlockSize_auto;
        inDatPath;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        outputDeps = getLabelInternOutputDependencies( obj )
        y = label( obj, annotations )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = Base( varargin )
            obj = obj@Core.IdProcInterface();
            ip = inputParser;
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.parse( varargin{:} );
            obj.labelBlockSize_s = ip.Results.labelBlockSize_s;
            if isempty( obj.labelBlockSize_s )
                obj.labelBlockSize_auto = true;
            else
                obj.labelBlockSize_auto = false;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            in = obj.loadInputData( wavFilepath );
            obj.inDatPath = obj.inputProc.getOutputFilepath( wavFilepath );
            obj.y = [];
            for blockAnnotation = in.blockAnnotations'
                if obj.labelBlockSize_auto
                    obj.labelBlockSize_s = ...
                                 blockAnnotation.blockOffset - blockAnnotation.blockOnset;
                end
                obj.y(end+1,:) = obj.label( blockAnnotation );
                if obj.labelBlockSize_auto
                    obj.labelBlockSize_s = [];
                end
                fprintf( '.' );
            end
        end
        %% -------------------------------------------------------------------------------

        % override of DataProcs.IdProcInterface's method
        function out = loadProcessedData( obj, wavFilepath )
            tmpOut = loadProcessedData@Core.IdProcInterface( obj, wavFilepath );
            obj.y = tmpOut.y;
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
        
        % override of DataProcs.IdProcInterface's method
        function save( obj, wavFilepath, ~ )
            out.y = obj.y;
            out.inDatPath = obj.inDatPath;
            save@Core.IdProcInterface( obj, wavFilepath, out ); 
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.v = 1;
            outputDeps.labelBlockSize = obj.labelBlockSize_s;
            outputDeps.labelBlockSize_auto = obj.labelBlockSize_auto;
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
            out.x(any(isnan(out.y))) = [];
            out.a(any(isnan(out.y))) = [];
            out.y(any(isnan(out.y))) = [];
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

