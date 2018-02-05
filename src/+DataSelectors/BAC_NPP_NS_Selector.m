classdef BAC_NPP_NS_Selector < DataSelectors.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        discardNsNotNa = true;
        subsampleToSmallestClass = false;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC_NPP_NS_Selector( discardNsNotNa, subsampleToSmallestClass )
            obj = obj@DataSelectors.Base();
            if nargin >= 1
                obj.discardNsNotNa = discardNsNotNa;
            end
            if nargin >= 2
                obj.subsampleToSmallestClass = subsampleToSmallestClass;
            end
        end
        % -----------------------------------------------------------------
    
        function [selectFilter] = getDataSelection( obj, sampleIdsIn, maxDataSize )
            selectFilter = true( size( sampleIdsIn ) );
            ba = getDataHelper( obj.data, 'blockAnnotations' );
            ba = ba(sampleIdsIn);
            ba_ns = cat( 1, ba.nActivePointSrcs );
            if obj.discardNsNotNa
                % nPointSrcsSceneConfig is only in blockAnnotations if they
                % are loaded through GatherFeaturesProc
                ba_ns_scp = cat( 1, ba.nPointSrcsSceneConfig );
                nsNotNa = (ba_ns ~= ba_ns_scp) & ~(ba_ns == 0 & ba_ns_scp == 1);
                selectFilter(nsNotNa) = false;
            end
            obj.verboseOutput = sprintf( ['\nOut of a pool of %d samples,\n' ...
                                            'discard %d where na ~= ns\n'], ...
                                         numel( nsNotNa ), sum( nsNotNa ) );
            if ~any( selectFilter )
                return;
            end
            ba_pp = cat( 1, ba.posPresent );
            clear ba;
            y = getDataHelper( obj.data, 'y' );
            y = y(sampleIdsIn);
            y_ = y .* (ba_ns+1) .* (1 + ~ba_pp * 9);
            selectFilter = selectFilter(:) & (y_(:) ~= 1); % pos although ba_ns==0
            y_Idxs = find( selectFilter );
            [throwoutIdxs,nClassSamples,~,labels] = ...
                          DataSelectors.BAC_Selector.getBalThrowoutIdxs( y_(selectFilter), maxDataSize );
            y_throwoutIdxs = y_Idxs(throwoutIdxs);
            selectFilter(y_throwoutIdxs) = false;
            if obj.subsampleToSmallestClass
                nSmallestSample = min( nClassSamples );
                for ii = 1 : numel( labels )
                    nRemoveSamples = nClassSamples(ii) - nSmallestSample;
                    y_ii_idxs = find( (y_ == labels(ii)) & selectFilter );
                    rp = randperm( numel( y_ii_idxs ) );
                    ii_remove_idxs = y_ii_idxs(rp(1:nRemoveSamples));
                    selectFilter(ii_remove_idxs) = false;
                end
            end
            for ii = 1 : numel( labels )
                trueLabel = unique( y(y_==labels(ii)) );
                obj.verboseOutput = sprintf( ['%s' ...
                                              'randomly select %d/%d of class %d (%d)\n'], ...
                                             obj.verboseOutput, ...
                                             sum( y_(selectFilter) == labels(ii) ), ...
                                             sum( y_ == labels(ii) ), ...
                                             labels(ii), trueLabel );
            end
        end
        % -----------------------------------------------------------------

    end
    % ---------------------------------------------------------------------
    
    methods (Static)
    end

end

