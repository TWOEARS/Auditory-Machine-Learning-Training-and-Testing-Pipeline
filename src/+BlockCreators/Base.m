classdef Base < Core.IdProcInterface
    % Base Abstract base class for extraction of blocks from streams (wavs)
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
        shiftSize_s;                % shift between blocks
        blockSize_s;                % size of the AFE data block in seconds
        afeBlocks;
        blockAnnotations;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract, Access = protected)
        outputDeps = getBlockCreatorInternOutputDependencies( obj )
        [afeBlocks, blockAnnotations] = blockify( obj, afeStream, streamAnnotations )
    end

    %% ----------------------------------------------------------------------------------- 
    methods
        
        function obj = Base( blockSize_s, shiftsize_s )
            obj = obj@Core.IdProcInterface();
            obj.blockSize_s = blockSize_s;
            obj.shiftSize_s = shiftsize_s;
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            obj.inputProc.sceneId = obj.sceneId;
            in = obj.loadInputData( wavFilepath, 'afeData', 'annotations' );
            try
                [obj.afeBlocks, obj.blockAnnotations] = ...
                                               obj.blockify( in.afeData, in.annotations );
            catch err
                fprintf( 'error connecting %s.', ...
                                         obj.inputProc.getOutputFilepath( wavFilepath ) );
                rethrow( err );
            end
        end
        %% -------------------------------------------------------------------------------

        function afeBlock = cutDataBlock( obj, afeData, backOffset_s )
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = afeData.keys
                afeSignal = afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    afeSignalExtract = cell( size( afeSignal ) );
                    for ii = 1 : numel( afeSignal )
                        afeSignalExtract{ii} = ...
                            afeSignal{ii}.cutSignalCopyReducedToArray( obj.blockSize_s,...
                                                                       backOffset_s );
                    end
                else
                    afeSignalExtract = ...
                        afeSignal.cutSignalCopyReducedToArray( obj.blockSize_s, ...
                                                               backOffset_s );
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
                fprintf( '.' );
            end
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.blockSize = obj.blockSize_s;
            outputDeps.shiftSize = obj.shiftSize_s;
            outputDeps.v = 2;
            outputDeps.blockProc = obj.getBlockCreatorInternOutputDependencies();
        end
        %% ------------------------------------------------------------------------------- 

        function out = getOutput( obj, varargin )
            if nargin < 2  || any( strcmpi( 'afeBlocks', varargin ) )
                out.afeBlocks = obj.afeBlocks;
            end
            if nargin < 2  || any( strcmpi( 'blockAnnotations', varargin ) )
                out.blockAnnotations = obj.blockAnnotations;
            end
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

