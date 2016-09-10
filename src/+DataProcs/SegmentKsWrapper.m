classdef SegmentKsWrapper < DataProcs.BlackboardKsWrapper
    % Wrapping the SegmentationKS
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        varAzmPrior;
        currentVarAzms;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SegmentKsWrapper( paramFilepath, varargin )
            segmentKs = StreamSegregationKS( paramFilepath, varargin{:} );
            obj = obj@DataProcs.BlackboardKsWrapper( segmentKs );
            obj.varAzmPrior = 0;
        end
        %% -------------------------------------------------------------------------------
        
        function procBlock = preproc( obj, blockAnnotations )
            procBlock = true;
            absAzms = blockAnnotations.srcAzms;
            if isstruct( absAzms ) || size( absAzms, 1 ) > 1
                error( 'AMLTTP:procBinding:singleValueBlockAnnotationsNeeded', ...
                    'SegmentKsWrapper can only handle one azm value per source per block.' );
            end
            absAzms(isnan(absAzms)) = [];
            if isempty( absAzms )
                procBlock = false; 
                return;
            end
            azmVar = obj.varAzmPrior * (2*rand( size( absAzms ) ) - 1);
            obj.currentVarAzms = wrapTo180( absAzms + azmVar );
            obj.ks.setFixedAzimuths( obj.currentVarAzms );
            obj.ks.setBlocksize( blockAnnotations.blockOffset ...
                                                          - blockAnnotations.blockOnset );
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj, afeData, blockAnnotations )
            segHypos = obj.bbs.blackboard.getLastData( 'segmentationHypotheses' );
            for ii = 1 : numel( segHypos.data )
                obj.out.afeBlocks{end+1,1} = obj.softmaskAFE( afeData, segHypos, ii );
                baIdx = find( obj.currentVarAzms == segHypos.data(ii).refAzm );
                if numel( baIdx ) > 1
                    nSameRefAzms = find( segHypos.data(ii).refAzm == [segHypos.data(1:ii).refAzm] );
                    baIdx = baIdx(numel( nSameRefAzms ));
                end
                if isempty(obj.out.blockAnnotations)
                    obj.out.blockAnnotations = obj.maskBA( blockAnnotations, baIdx );
                else
                    obj.out.blockAnnotations(end+1,1) = obj.maskBA( blockAnnotations, baIdx );
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getKsInternOutputDependencies( obj )
            outputDeps.v = 5;
            outputDeps.params = obj.ks.observationModel.trainingParameters;
            outputDeps.afeHashs = obj.ks.reqHashs;
            outputDeps.varAzmPrior = obj.varAzmPrior;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        %% -------------------------------------------------------------------------------
        
        function afeBlock = softmaskAFE( obj, afeBlock, segHypos, idx_mask )
            afeBlock = SegmentIdentityKS.maskAFEData( afeBlock, ...
                                                      segHypos.data(idx_mask).softMask, ...
                                                      segHypos.data(idx_mask).cfHz, ...
                                                      segHypos.data(idx_mask).hopSize );
        end
        %% -------------------------------------------------------------------------------
        
        function blockAnnotations = maskBA( obj, blockAnnotations, srcIdx )
            baFields = fieldnames( blockAnnotations );
            for ff = 1 : numel( baFields )
                if isstruct( blockAnnotations.(baFields{ff}) )
                    baIsSrcIdEq = ...
                          [blockAnnotations.(baFields{ff}).(baFields{ff}){:,2}] == srcIdx;
                    blockAnnotations.(baFields{ff}).t.onset(~baIsSrcIdEq) = [];
                    blockAnnotations.(baFields{ff}).t.offset(~baIsSrcIdEq) = [];
                    blockAnnotations.(baFields{ff}).(baFields{ff})(~baIsSrcIdEq,:) = [];
                    blockAnnotations.(baFields{ff}).(baFields{ff})(:,2) = ...
                                                   repmat( {1}, sum( baIsSrcIdEq ), 1 );
                elseif iscell( blockAnnotations.(baFields{ff}) ) ...
                        || numel( blockAnnotations.(baFields{ff}) ) > 1
                    baIsSrcIdEq = false( size( blockAnnotations.(baFields{ff}) ) );
                    baIsSrcIdEq(srcIdx) = true;
                    blockAnnotations.(baFields{ff})(~baIsSrcIdEq) = [];
                end
            end
            blockAnnotations.mixEnergy = blockAnnotations.srcEnergy{1};
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

