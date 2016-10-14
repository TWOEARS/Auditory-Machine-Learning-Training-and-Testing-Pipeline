classdef SegmentKsWrapper < DataProcs.BlackboardKsWrapper
    % Wrapping the SegmentationKS
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        varAzmPrior;
        currentVarAzms;
        dnnHash;
        nfHash;
        useDnnLocKs = false;
        useNsrcsKs = false;
        segmentKs;
        dnnLocKs;
        nsrcsKs;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SegmentKsWrapper( paramFilepath, varargin )
            ip = inputParser();
            ip.addOptional( 'useDnnLocKs', false );
            ip.addOptional( 'useNsrcsKs', false );
            ip.addOptional( 'nsrcsModelPath', './nsrcs.model.mat' );
            ip.parse( varargin{:} );
            segmentKs = StreamSegregationKS( paramFilepath );
            wrappedKss = {};
            if ip.Results.useDnnLocKs
                dnnLocKs = DnnLocationKS();
                dnnHash = calcDataHash( dnnLocKs.DNNs );
                nfHash = calcDataHash( dnnLocKs.normFactors );
                wrappedKss{end+1} = dnnLocKs;
            else
                dnnLocKs = [];
                dnnHash = [];
                nfHash = [];
            end
            if ip.Results.useDnnLocKs && ip.Results.useNsrcsKs
                [mdir, mname] = fileparts( ip.Results.nsrcsModelPath );
                [~, mname] = fileparts( mname );
                nsrcsKs = NumberOfSourcesKS( mname, mdir, false );
                wrappedKss{end+1} = nsrcsKs;
            else
                nsrcsKs = [];
            end
            wrappedKss{end+1} = segmentKs;
            obj = obj@DataProcs.BlackboardKsWrapper( wrappedKss );
            obj.varAzmPrior = 0;
            obj.dnnHash = dnnHash;
            obj.nfHash = nfHash;
            obj.useDnnLocKs = ip.Results.useDnnLocKs;
            obj.useNsrcsKs = ip.Results.useNsrcsKs;
            obj.segmentKs = segmentKs;
            obj.dnnLocKs = dnnLocKs;
            obj.nsrcsKs = nsrcsKs;
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
            if ~obj.useDnnLocKs
                azmVar = obj.varAzmPrior * (2*rand( size( absAzms ) ) - 1);
                obj.currentVarAzms = wrapTo180( absAzms + azmVar );
                obj.segmentKs.setFixedAzimuths( obj.currentVarAzms );
            else
                obj.currentVarAzms = wrapTo180( absAzms );
                obj.segmentKs.setFixedAzimuths( [] );
                warning( 'off', 'BBS:badBlockTimeRequest' );
            end
            if ~obj.useNsrcsKs
                obj.segmentKs.setFixedNoSrcs( numel( absAzms ) );
            else
                obj.segmentKs.setFixedNoSrcs( [] );
            end
            obj.segmentKs.setBlocksize( blockAnnotations.blockOffset ...
                                                - blockAnnotations.blockOnset );
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj, afeData, blockAnnotations )
            segHypos = obj.bbs.blackboard.getLastData( 'segmentationHypotheses' );
            nMasks = numel( segHypos.data );
            nTrue = numel( obj.currentVarAzms );
            hypCurAzmDists = zeros( nMasks, numel( obj.currentVarAzms ) );
            for ii = 1 : nMasks
                hypAzm = wrapTo180( segHypos.data(ii).refAzm );
                hypCurAzmDists(ii,:) = ...
                                abs( wrapTo180( obj.currentVarAzms - hypAzm ) );
            end
            [~,minAzmDistComb] = min( hypCurAzmDists, [], 1 );
            for ii = 1 : nMasks
                obj.out.afeBlocks{end+1,1} = obj.softmaskAFE( afeData, segHypos, ii );
                baIdx = find( minAzmDistComb == ii );
                if isempty(obj.out.blockAnnotations)
                    obj.out.blockAnnotations = obj.maskBA( blockAnnotations, baIdx );
                else
                    obj.out.blockAnnotations(end+1,1) = obj.maskBA( blockAnnotations, baIdx );
                end
            end
            warning( 'on', 'BBS:badBlockTimeRequest' );
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getKsInternOutputDependencies( obj )
            outputDeps.v = 6;
            outputDeps.useDnnLocKs = obj.useDnnLocKs;
            outputDeps.useNsrcsKs = obj.useNsrcsKs;
            outputDeps.params = obj.kss{end}.observationModel.trainingParameters;
            [~,outputDeps.afeHashs] = obj.getAfeRequests();
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
        
        function blockAnnotations = maskBA( obj, blockAnnotations, srcIdxs )
            rSrcIdxs = 1:max( srcIdxs );
            rSrcIdxs(srcIdxs) = 1:numel(srcIdxs);
            baFields = fieldnames( blockAnnotations );
            for ff = 1 : numel( baFields )
                if isstruct( blockAnnotations.(baFields{ff}) )
                    baSrcs = blockAnnotations.(baFields{ff}).(baFields{ff})(:,2);
                    baIsSrcIdEq = cellfun( @(x)( any( x == srcIdxs) ), baSrcs );
                    blockAnnotations.(baFields{ff}).t.onset(~baIsSrcIdEq) = [];
                    blockAnnotations.(baFields{ff}).t.offset(~baIsSrcIdEq) = [];
                    blockAnnotations.(baFields{ff}).(baFields{ff})(~baIsSrcIdEq,:) = [];
                    blockAnnotations.(baFields{ff}).(baFields{ff})(:,2) = ...
                        cellfun( @(x)(rSrcIdxs(x)), ...
                        blockAnnotations.(baFields{ff}).(baFields{ff})(:,2), ...
                                                       'UniformOutput', false );
                elseif ~strcmpi('mixEnergy',baFields{ff}) && ...
                        (iscell( blockAnnotations.(baFields{ff}) ) ...
                        || numel( blockAnnotations.(baFields{ff}) ) > 1)
                    baIsSrcIdEq = false( size( blockAnnotations.(baFields{ff}) ) );
                    baIsSrcIdEq(srcIdxs) = true;
                    blockAnnotations.(baFields{ff})(~baIsSrcIdEq) = [];
                end
            end
%             blockAnnotations.mixEnergy = blockAnnotations.srcEnergy{1};
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

