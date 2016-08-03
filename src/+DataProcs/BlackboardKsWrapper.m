classdef BlackboardKsWrapper < Core.IdProcInterface
    % Abstract base class for wrapping KS into an emulated blackboard
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        ks;
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
        
        function obj = BlackboardKsWrapper( ks )
            obj = obj@Core.IdProcInterface();
            obj.ks = ks;
            obj.bbs = BlackboardSystem( false );
            obj.ks.setBlackboardAccess( obj.bbs.blackboard, obj.bbs );
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
            obj.out = struct( 'afeBlocks', {{}}, 'blockAnnotations', {[]} );
            for aa = 1 : numel( afes )
                afeData = afes{aa};
                % initialize blackboard environment for block
                for ii = 1 : numel( obj.ks.reqHashs )
                    reqSignal = afeData(ii + obj.afeDataIndexOffset);
                    if iscell(reqSignal) && length(reqSignal)==1
                        reqSignal = reqSignal{1};
                    end
                    obj.bbs.blackboard.addSignal( ...
                              obj.ks.reqHashs{ii}, reqSignal );
                end
                obj.ks.setActiveArgument( 'nil', 0, 'nil' );
                obj.ks.lastBlockEnd = zeros( 1, numel( obj.ks.reqHashs ) );
                obj.bbs.blackboard.setSoundTimeIdx( 0 );
                obj.ks.timeStamp();
                obj.bbs.blackboard.setSoundTimeIdx( ...
                                               bas(aa).blockOffset - bas(aa).blockOnset );
                blockHeadOrientation = 0;
                % TODO: read head orientation from block annotations
                obj.bbs.blackboard.addData( 'headOrientation', blockHeadOrientation );
                % run ks
                obj.preproc( bas(aa) ); % add any ks-specific data to blackboard
                fprintf( '`' );
                obj.ks.execute();
                fprintf( '''' );
                for ii = (1 : numel( obj.ks.reqHashs )) + obj.afeDataIndexOffset
                    afeData.remove( ii );
                end
                obj.postproc( afeData, bas(aa) ); % read ks results from bb, create output
                obj.bbs.blackboard.deleteData();
                fprintf( '´' );
            end
            warning( 'on', 'BB:tNotIncreasing' );
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
            out.afeBlocks = obj.out.afeBlocks;
            out.blockAnnotations = obj.out.blockAnnotations;
        end
        %% -------------------------------------------------------------------------------

    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

