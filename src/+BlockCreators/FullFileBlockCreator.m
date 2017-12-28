classdef FullFileBlockCreator < BlockCreators.Base
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = FullFileBlockCreator()
            obj = obj@BlockCreators.Base( inf, 0 );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.v = 1;
        end
        %% ------------------------------------------------------------------------------- 

        function [blockAnnots,afeBlocks] = blockify( obj, afeData, annotations )
            annotations = obj.extendAnnotations( annotations );
            anyAFEsignal = afeData(1);
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            streamLen_s = double( size( anyAFEsignal.Data, 1 ) ) / anyAFEsignal.FsHz;
            if nargout > 1
                afeBlocks = {afeData};
            end
            blockAnnots = annotations;
            blockAnnots.blockOnset = 0;
            blockAnnots.blockOffset = streamLen_s;
        end
        %% ------------------------------------------------------------------------------- 
        
        % TODO: this is the wrong place for the annotation computation; it
        % should be done in SceneEarSignalProc -- and is now here, for the
        % moment, to avoid recomputation with SceneEarSignalProc.
        
        function annotations = extendAnnotations( obj, annotations )
            annotations.srcSNR.t = annotations.globalSrcEnergy.t;
            annotations.srcSNR.srcSNR = cell( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.srcSNR_db.t = annotations.globalSrcEnergy.t;
            annotations.srcSNR_db.srcSNR_db = cell( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.nrj.t = annotations.globalSrcEnergy.t;
            annotations.nrj.nrj = cell( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.nrj_db.t = annotations.globalSrcEnergy.t;
            annotations.nrj_db.nrj_db = cell( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.nrjOthers.t = annotations.globalSrcEnergy.t;
            annotations.nrjOthers.nrjOthers = cell( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.nrjOthers_db.t = annotations.globalSrcEnergy.t;
            annotations.nrjOthers_db.nrjOthers_db = cell( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            annotations.nActivePointSrcs.t = annotations.globalSrcEnergy.t;
            annotations.nActivePointSrcs.nActivePointSrcs = cell( size( annotations.globalSrcEnergy.globalSrcEnergy ) );
            currentDependencies = obj.getOutputDependencies();
            sceneConfig = currentDependencies.preceding.preceding.sceneCfg;
            if std( sceneConfig.snrRefs ) ~= 0
                error( 'AMLTTP:usage:snrRefMustBeSame', 'different snrRefs not supported' );
            end
            snrRef = sceneConfig.snrRefs(1);
            srcsGlobalRefEnergyMeanChannel = cellfun( @(c)(sum(c) ./ 2 ), ...
                                            annotations.globalSrcEnergy.globalSrcEnergy );
            srcsGlobalRefEnergyMeanChannel_db = 10 * log10( srcsGlobalRefEnergyMeanChannel );
            snrRefNrjOffsets = ...
                             cell2mat( annotations.globalNrjOffsets.globalNrjOffsets ) ...
                             - annotations.globalNrjOffsets.globalNrjOffsets{snrRef};
            for ss = 1 : size( srcsGlobalRefEnergyMeanChannel, 2 )
                otherIdxs = 1 : size( srcsGlobalRefEnergyMeanChannel, 2 );
                otherIdxs(ss) = [];
                srcsCurrentSrcRefEnergy_db = srcsGlobalRefEnergyMeanChannel_db ...
                                                               - snrRefNrjOffsets(ss);
                srcsCurrentSrcRefEnergy = 10.^(srcsCurrentSrcRefEnergy_db./10);
                sumOtherSrcsEnergy = sum( srcsCurrentSrcRefEnergy(:,otherIdxs), 2 );
                annotations.nrjOthers.nrjOthers(:,ss) = num2cell( single( ...
                                                                   sumOtherSrcsEnergy ) );
                annotations.nrjOthers_db.nrjOthers_db(:,ss) = num2cell( single( ...
                                                     10 * log10( sumOtherSrcsEnergy ) ) );
                annotations.nrj.nrj(:,ss) = num2cell( single( ...
                                                        srcsCurrentSrcRefEnergy(:,ss) ) );
                annotations.nrj_db.nrj_db(:,ss) = num2cell( single( ...
                                                     srcsCurrentSrcRefEnergy_db(:,ss) ) );
                annotations.srcSNR.srcSNR(:,ss) = num2cell( single( ...
                                  srcsCurrentSrcRefEnergy(:,ss) ./ sumOtherSrcsEnergy ) );
                annotations.srcSNR_db.srcSNR_db(:,ss) = num2cell( single( ...
                                                   srcsCurrentSrcRefEnergy_db(:,ss) ...
                                                   - 10 * log10( sumOtherSrcsEnergy ) ) );
            end
            haveSrcsEnergy = srcsGlobalRefEnergyMeanChannel_db > -40;
            isAmbientSource = all( isnan( annotations.srcAzms.srcAzms ), 1 );
            haveSrcsEnergy(:,isAmbientSource) = [];
            annotations.nActivePointSrcs.nActivePointSrcs = num2cell( single( sum( haveSrcsEnergy, 2 ) ) );
        end
        %% ------------------------------------------------------------------------------- 
    
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

