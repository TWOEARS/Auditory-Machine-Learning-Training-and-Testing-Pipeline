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
        preproc( obj, blockAnnotations )
        postproc( obj )
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
            inData = obj.loadInputData( wavFilepath );
            bas = inData.blockAnnotations;
            afes = inData.afeBlocks;
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
                obj.postproc(); % read ks results from blackboard
            end
            warning( 'on', 'BB:tNotIncreasing' );
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

        

