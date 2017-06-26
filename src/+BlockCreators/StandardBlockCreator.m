classdef StandardBlockCreator < BlockCreators.Base
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = StandardBlockCreator( blockSize_s, shiftSize_s )
            obj = obj@BlockCreators.Base( blockSize_s, shiftSize_s );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.v = 3;
        end
        %% ------------------------------------------------------------------------------- 

        function [blockAnnots,afeBlocks] = blockify( obj, afeData, annotations )
            annotations = obj.extendAnnotations( annotations );
            anyAFEsignal = afeData(1);
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            streamLen_s = double( size( anyAFEsignal.Data, 1 ) ) / anyAFEsignal.FsHz;
            backOffsets_s = ...
                       0.0 : obj.shiftSize_s : max( streamLen_s-obj.shiftSize_s+0.01, 0 );
            blockAnnots = repmat( annotations, numel( backOffsets_s ), 1 );
            blockOffsets = [streamLen_s - backOffsets_s]';
            blockOnsets = max( 0, blockOffsets - obj.blockSize_s );
            aFields = fieldnames( annotations );
            isSequenceAnnotation = cellfun( @(af)(...
                      isstruct( annotations.(af) ) && isfield( annotations.(af), 't' ) ...
                                                                             ), aFields );
            sequenceAfields = aFields(isSequenceAnnotation);
            afeBlocks = cell( numel( backOffsets_s ), 1 );
            for ii = 1 : numel( backOffsets_s )
                backOffset_s = backOffsets_s(ii);
                if nargout > 1
                    afeBlocks{ii} = obj.cutDataBlock( afeData, backOffset_s );
                end
                blockOn = blockOnsets(ii);
                blockOff = blockOffsets(ii);
                blockAnnots(ii).blockOnset = blockOn;
                blockAnnots(ii).blockOffset = blockOff;
                for jj = 1 : numel( sequenceAfields )
                    seqAname = sequenceAfields{jj};
                    annot = annotations.(seqAname);
                    if ~isstruct( annot.t ) % time series
                        if length( annot.t ) == size( annot.(seqAname), 1 )
                            isTinBlock = (annot.t >= blockOn) & (annot.t <= blockOff);
                            blockAnnots(ii).(seqAname).(seqAname)(~isTinBlock,:) = [];
                            blockAnnots(ii).(seqAname).t(~isTinBlock) = [];
                        else
                            error( 'unexpected annotations sequence structure' );
                        end
                    elseif all( isfield( annot.t, {'onset','offset'} ) ) % event series
                        if isequal( size( annot.t.onset ), size( annot.t.offset ) ) && ...
                                length( annot.t.onset ) == size( annot.(seqAname), 1 )
                            isEventInBlock = arrayfun( @(eon,eoff)(...
                                               (eon >= blockOn && eon <= blockOff) || ...
                                              (eoff >= blockOn && eoff <= blockOff) || ...
                                               (eon <= blockOn && eoff >= blockOff)...
                                                       ), annot.t.onset, annot.t.offset );
                            blockAnnots(ii).(seqAname).(seqAname)(~isEventInBlock,:) = [];
                            blockAnnots(ii).(seqAname).t.onset(~isEventInBlock) = [];
                            blockAnnots(ii).(seqAname).t.offset(~isEventInBlock) = [];
                        else
                            error( 'unexpected annotations sequence structure' );
                        end
                    else
                        error( 'unexpected annotations sequence structure' );
                    end
                end
            end
            afeBlocks = flipud( afeBlocks );
            blockAnnots = flipud( blockAnnots );
        end
        %% ------------------------------------------------------------------------------- 
        
        % TODO: this is the wrong place for the annotation computation; it
        % should be done in SceneEarSignalProc -- and is now here, for the
        % moment, to avoid recomputation with SceneEarSignalProc.
        
        function annotations = extendAnnotations( obj, annotations )
            currentDependencies = obj.getOutputDependencies();
            sceneConfig = currentDependencies.preceding.preceding.sceneCfg;
            annotations.srcSNR.t = annotations.srcEnergy.t;
            annotations.srcSNR.srcSNR = cell( size( annotations.srcEnergy.srcEnergy ) );
            annotations.srcSNR_avgSelf.t = annotations.srcEnergy.t;
            annotations.srcSNR_avgSelf.srcSNR_avgSelf = cell( size( annotations.srcEnergy.srcEnergy ) );
            annotations.oneVsAllAvgSnrs.t = annotations.srcEnergy.t;
            avgBilateralSNRs = nan( numel( sceneConfig.sources ) );
            if std( sceneConfig.snrRefs ) ~= 0
                error( 'AMLTTP:usage:snrRefMustBeSame', 'different snrRefs not supported' );
            end
            for ss = 1 : numel( sceneConfig.sources )
                avgBilateralSNRs(ss,ss) = 0;
                avgBilateralSNRs(ss,sceneConfig.snrRefs(ss)) = sceneConfig.SNRs(ss).value;
            end
            refSNRs = avgBilateralSNRs(:,sceneConfig.snrRefs(1));
            oneVsAllSNRs = zeros( size( refSNRs ) );
            for ss = 1 : numel( sceneConfig.sources )
                if ss ~= sceneConfig.snrRefs(ss)
                    for sss = 1 : size( avgBilateralSNRs, 1 )
                        if ~isnan( avgBilateralSNRs(sss,ss) )
                            refDiff = avgBilateralSNRs(sss,ss) - refSNRs(sss);
                            avgBilateralSNRs(:,ss) = refSNRs + refDiff;
                            break;
                        end
                    end
                end
                idxs = 1 : size( avgBilateralSNRs, 1 );
                idxs(ss) = [];
                oneVsAllSNRs(ss) = addSnrs( avgBilateralSNRs(idxs,ss) );
            end
            annotations.oneVsAllAvgSnrs.oneVsAllAvgSnrs = ...
                                      repmat( num2cell( single( oneVsAllSNRs )' ), ...
                                              numel( annotations.oneVsAllAvgSnrs.t ), 1 );
            srcsRelEnergy = cellfun( @mean, annotations.srcEnergy.srcEnergy );
            meanSrcsRelEnergy = nan( 1, size( srcsRelEnergy, 2 ) );
            for ss = 1 : size( srcsRelEnergy, 2 )
                meanSrcsRelEnergy(ss) = mean( srcsRelEnergy(srcsRelEnergy(:,ss) >= -40,ss) );
            end
            srcsEnergy = srcsRelEnergy - repmat( meanSrcsRelEnergy, ...
                                                 numel( annotations.srcEnergy.t ), 1 );
            for ss = 1 : numel( sceneConfig.sources )
                srcBilateralSnrs = repmat( avgBilateralSNRs(ss,:), ...
                                           numel( annotations.srcEnergy.t ), 1 );
                idxs = 1 : size( avgBilateralSNRs, 1 );
                idxs(ss) = [];
                tmpSE = srcsEnergy + srcBilateralSnrs;
                for ii = 1 : size( tmpSE, 1 )
                    annotations.srcSNR_avgSelf.srcSNR_avgSelf{ii,ss} = single( ...
                                                             addSnrs( -tmpSE(ii,idxs) ) );
                    annotations.srcSNR.srcSNR{ii,ss} = single( ...
                        annotations.srcSNR_avgSelf.srcSNR_avgSelf{ii,ss} + tmpSE(ii,ss) );
                end
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

        

