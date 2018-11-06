classdef BlackboardKsWrapper < Core.IdProcInterface
    % Abstract base class for wrapping KS into an emulated blackboard
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        kss;
        bbs;
        afeDataIndexOffset;
        out;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        preproc( obj, blockAnnotations )
        postproc( obj, afeData, blockAnnotations )
        outputDeps = getKsInternOutputDependencies( obj )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = BlackboardKsWrapper( kss )
            obj = obj@Core.IdProcInterface();
            if ~iscell( kss )
                obj.kss = {kss};
            else
                obj.kss = kss;
            end
            obj.bbs = BlackboardSystem( false );
            for ii = 1 : numel( kss )
                obj.kss{ii}.setBlackboardAccess( obj.bbs.blackboard, obj.bbs );
            end
        end
        %% -------------------------------------------------------------------------------

        function [afeRequests, ksReqHashes] = getAfeRequests( obj )
            afeRequests = [];
            ksReqHashes = [];
            for ii = 1 : numel( obj.kss )
                afeRequests = [afeRequests obj.kss{ii}.requests];
                ksReqHashes = [ksReqHashes obj.kss{ii}.reqHashs];
            end
        end
        %% -------------------------------------------------------------------------------

        function obj = setAfeDataIndexOffset( obj, afeDataIndexOffset )
            obj.afeDataIndexOffset = afeDataIndexOffset;
        end
        %% -------------------------------------------------------------------------------
        
        function process( obj, wavFilepath )
            warning( 'off', 'BB:tNotIncreasing' );
            inData = obj.loadInputData( wavFilepath, 'blockAnnotations', 'afeBlocks' );
            bas = inData.blockAnnotations;
            afes = inData.afeBlocks;
            obj.out = struct( 'ksData', {{}}, 'blockAnnotations', {{}} );
            [~,ksReqHashes] = obj.getAfeRequests();
            for aa = 1 : numel( afes )
                afeData = afes{aa};
                % initialize blackboard environment for block
                for ii = 1 : numel( ksReqHashes )
                    reqSignal = afeData(ii + obj.afeDataIndexOffset);
                    if iscell(reqSignal) && length(reqSignal)==1
                        reqSignal = reqSignal{1};
                    end
                    obj.bbs.blackboard.addSignal( ...
                              ksReqHashes{ii}, reqSignal );
                end
                obj.bbs.blackboard.setSoundTimeIdx( 0 );
                for ii = 1 : numel( obj.kss )
                    obj.kss{ii}.setActiveArgument( 'nil', 0, 'nil' );
                    obj.kss{ii}.lastBlockEnd = zeros( 1, numel( obj.kss{ii}.reqHashs ) );
                    obj.kss{ii}.timeStamp();
                end
                currentBBtime = bas(aa).blockOffset - bas(aa).blockOnset;
                obj.bbs.blackboard.setSoundTimeIdx( currentBBtime );
                blockHeadOrientation = 0;
                % TODO: read head orientation from block annotations
                obj.bbs.blackboard.addData( 'headOrientation', blockHeadOrientation );
                % run ks
                procBlock = obj.preproc( bas(aa) ); % add any ks-specific data to blackboard
                if ~procBlock, continue; end
                fprintf( '.' );
                for ii = 1 : numel( obj.kss )
                    obj.kss{ii}.setActiveArgument('n/a', currentBBtime, 'n/a' );
                    obj.kss{ii}.execute();
                    fprintf( '.' );
                end
                for ii = 1 : numel( ksReqHashes )
                    afeData.remove(ii + obj.afeDataIndexOffset);
                end
                obj.postproc( afeData, bas(aa) ); % read ks results from bb, create output
                obj.bbs.blackboard.deleteData();
                fprintf( ',' );
            end
            warning( 'on', 'BB:tNotIncreasing' );
        end
        %% -------------------------------------------------------------------------------

        % override of DataProcs.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            [tmpOut, outFilepath] = loadProcessedData@Core.IdProcInterface( ...
                                                obj, wavFilepath, 'ksData', 'blockAnnotations' );
            out.ksData = tmpOut.ksData;
            out.blockAnnotations = tmpOut.blockAnnotations;
            if nargin < 3  || any( strcmpi( 'afeBlocks', varargin ) )
                inData = obj.loadInputData( wavFilepath, 'afeBlocks' );
                out.afeBlocks = inData.afeBlocks;
            end
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

        function out = getOutput( obj, varargin )
            out.ksData = obj.out.ksData;
            out.blockAnnotations = obj.out.blockAnnotations;
        end
        %% -------------------------------------------------------------------------------

    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

