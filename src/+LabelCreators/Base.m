classdef Base < Core.IdProcInterface
    % Base Abstract base class for labeling blocks
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
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
            in = obj.loadInputData( wavFilepath, 'blockAnnotations' );
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
        function out = loadProcessedData( obj, wavFilepath, varargin )
            tmpOut = loadProcessedData@Core.IdProcInterface( obj, wavFilepath, 'y', 'inDatPath' );
            obj.y = tmpOut.y;
            obj.inDatPath = tmpOut.inDatPath;
            try
                out = obj.getOutput;
            catch err
                if strcmp( 'AMLTTP:dataprocs:cacheFileCorrupt', err.msgIdent )
                    error( 'AMLTTP:dataprocs:cacheFileCorrupt',...
                           '%s \n%s corrupt -- delete and restart.', ...
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
                error( 'AMLTTP:dataprocs:cacheFileCorrupt', '%s not found.', obj.inDatPath );
            end
            inDat = load( obj.inDatPath, 'inDatPath', 'x' );
            inDat2 = load( inDat.inDatPath, 'blockAnnotations' );
            out.x = inDat.x;
            out.a = inDat2.blockAnnotations;
            out.y = obj.y;
            out.x(any(isnan(out.y),2),:) = [];
            out.a(any(isnan(out.y),2)) = [];
            out.y(any(isnan(out.y),2),:) = [];
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

