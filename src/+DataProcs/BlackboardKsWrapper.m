classdef BlackboardKsWrapper < Core.IdProcInterface
    % Abstract base class for wrapping KS into an emulated blackboard
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
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
        
        function obj = BlackboardKsWrapper( ks, afeDataIndexOffset )
            obj = obj@Core.IdProcInterface();
            obj.ks = ks;
            obj.bbs = BlackboardSystem( false );
            obj.ks.setBlackboardAccess( obj.bbs.blackboard, obj.bbs );
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
                    obj.bbs.blackboard.addSignal( ...
                              obj.ks.reqhashs{ii}, afeData(ii + obj.afeDataIndexOffset) );
                end
                obj.ks.setActiveArgument( 'nil', 0, 'nil' );
                obj.ks.lastBlockEnd = zeros( 1, numel( obj.ks.reqHashs ) );
                obj.bbs.blackboard.currentSoundTimeIdx = 0;
                obj.ks.timeStamp();
                obj.bbs.blackboard.currentSoundTimeIdx = ...
                                                 bas(aa).blockOffset - bas(aa).blockOnset;
                blockHeadOrientation = 0;
                % TODO: read head orientation from block annotations
                obj.bbs.blackboard.addData( 'headOrientation', blockHeadOrientation );
                % run ks
                obj.preproc( bas(aa) ); % add any ks-specific data to blackboard
                obj.ks.execute();
                afeData.remove( (1 : numel( obj.ks.reqHashs )) + obj.afeDataIndexOffset )
                obj.postproc( afeData, bas(aa) ); % read ks results from bb, create output
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

        

