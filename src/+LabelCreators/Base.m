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
        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            [tmpOut, outFilepath] = loadProcessedData@Core.IdProcInterface( ...
                                                     obj, wavFilepath, 'y', 'inDatPath' );
            obj.y = tmpOut.y;
            obj.inDatPath = tmpOut.inDatPath;
            try
                out = obj.getOutput( varargin{:} );
            catch err
                if strcmp( 'AMLTTP:dataprocs:cacheFileCorrupt', err.identifier )
                    error( 'AMLTTP:dataprocs:cacheFileCorrupt',...
                           '%s', obj.getOutputFilepath( wavFilepath ) );
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

        function out = getOutput( obj, varargin )
            if ~exist( obj.inDatPath, 'file' )
                error( 'AMLTTP:dataprocs:cacheFileCorrupt', '%s not found.', obj.inDatPath );
            end
            out.y = obj.y;
            if nargin < 2  || any( strcmpi( 'x', varargin ) )
                inDat = load( obj.inDatPath, 'inDatPath', 'x' );
                out.x = inDat.x;
                out.x(any(isnan(out.y),2),:) = [];
            end
            if nargin < 2  || any( strcmpi( 'a', varargin ) )
                if ~exist( 'inDat', 'var' )
                    inDat = load( obj.inDatPath, 'inDatPath' );
                end
                inDat2 = load( inDat.inDatPath, 'blockAnnotations' );
                out.a = inDat2.blockAnnotations;
                out.a(any(isnan(out.y),2)) = [];
            end
            out.y(any(isnan(out.y),2),:) = [];
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

