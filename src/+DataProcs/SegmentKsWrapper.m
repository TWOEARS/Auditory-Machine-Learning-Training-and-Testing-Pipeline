classdef SegmentKsWrapper < DataProcs.BlackboardKsWrapper
    % Wrapping the SegmentationKS
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        varAzmSigma;
        azmsGroundTruth;
        segSrcAssignmentMethod;
        dnnHash;
        nfHash;
        useDnnLocKs = false;
        useNsrcsKs = false;
        segmentKs;
        dnnLocKs;
        nsrcsKs;
        idKss;
        nsrcsBias;
        nsrcsRndPlusMinusBias;
        isNsrcsFixed;
        isAzmFixedUniform;
        softMaskExponent = 10;
        srcSegregateNrjThreshold
        od;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SegmentKsWrapper( paramFilepath, varargin )
            fprintf( 'Building SegmentKsWrapper...' );
            ip = inputParser();
            ip.addOptional( 'useDnnLocKs', false );
            ip.addOptional( 'useNsrcsKs', false );
            ip.addOptional( 'nsrcsParams', {} );
            ip.addOptional( 'segSrcAssignmentMethod', 'minDistance' );
            ip.addOptional( 'varAzmSigma', 0 );
            ip.addOptional( 'nsrcsBias', 0 );
            ip.addOptional( 'nsrcsRndPlusMinusBias', 0 );
            ip.addOptional( 'softMaskExponent', 10 );
            ip.addOptional( 'srcSegregateNrjThreshold', -40 );
            ip.parse( varargin{:} );
            segmentKs = StreamSegregationKS( paramFilepath ); 
            fprintf( '.' );
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
            fprintf( '.' );
            idKss = [];
            if ip.Results.useDnnLocKs && ip.Results.useNsrcsKs
                ipns = inputParser();
                ipns.addOptional( 'modelPath', './nsrcs.model.mat' );
                ipns.addOptional( 'useIdModels', false );
                ipns.addOptional( 'idModelpathes', {} );
                ipns.parse( ip.Results.nsrcsParams{:} );
                if ipns.Results.useIdModels
                    idKss = {};
                    mnames = {};
                    for ii = 1 : numel( ipns.Results.idModelpathes )
                        [mdir, mname] = fileparts( ipns.Results.idModelpathes{ii} );
                        [~, mnames{ii}] = fileparts( mname );
                        idKss{ii} = IdentityKS( mnames{ii}, mdir, false ); 
                        fprintf( '.' );
                    end
                    [~,idSort] = sort( mnames );
                    idKss = idKss(idSort);
                    wrappedKss = [wrappedKss idKss];
                end
                [mdir, mname] = fileparts( ipns.Results.modelPath );
                [~, mname] = fileparts( mname );
                nsrcsKs = NumberOfSourcesKS( mname, mdir, false, 'useIdModels', ipns.Results.useIdModels );
                fprintf( '.' );
                wrappedKss{end+1} = nsrcsKs;
            else
                nsrcsKs = [];
            end
            wrappedKss{end+1} = segmentKs;
            obj = obj@DataProcs.BlackboardKsWrapper( wrappedKss );
            obj.varAzmSigma = ip.Results.varAzmSigma;
            obj.azmsGroundTruth = [];
            obj.segSrcAssignmentMethod = ip.Results.segSrcAssignmentMethod;
            obj.dnnHash = dnnHash;
            obj.nfHash = nfHash;
            obj.useDnnLocKs = ip.Results.useDnnLocKs;
            obj.useNsrcsKs = ip.Results.useNsrcsKs;
            if obj.useNsrcsKs && ~obj.useDnnLocKs
                error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                       ['nSrcs model employment only supported if also using ' ...
                        'location model.'] );
            end
            obj.segmentKs = segmentKs;
            obj.dnnLocKs = dnnLocKs;
            obj.idKss = idKss;
            obj.nsrcsKs = nsrcsKs;
            obj.isNsrcsFixed = false;
            obj.isAzmFixedUniform = false;
            obj.nsrcsBias = ip.Results.nsrcsBias;
            if obj.useNsrcsKs && (obj.nsrcsBias ~= 0)
                error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                       ['nSrcs bias only supported if using ' ...
                        'nSrcs ground truth.'] );
            end
            if ischar( obj.nsrcsBias ) 
                if strfind( obj.nsrcsBias, 'fixed' ) == 1
                    obj.isNsrcsFixed = true;
                    obj.nsrcsBias = str2double( obj.nsrcsBias(6:end) );
                else
                    error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                          ['unrecognized nSrcs bias flag.'] );
                end
            end
            obj.nsrcsRndPlusMinusBias = ip.Results.nsrcsRndPlusMinusBias;
            if obj.useNsrcsKs && (obj.nsrcsRndPlusMinusBias ~= 0)
                error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                       ['nSrcs random bias only supported if using ' ...
                        'nSrcs ground truth.'] );
            end
            if ischar( obj.varAzmSigma ) 
                if strfind( obj.varAzmSigma, 'fixedUniform' ) == 1
                    obj.isAzmFixedUniform = true;
                else
                    error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                          ['unrecognized azm bias flag.'] );
                end
            end
            obj.softMaskExponent = ip.Results.softMaskExponent;
            obj.srcSegregateNrjThreshold = ip.Results.srcSegregateNrjThreshold;
            obj.od.params.compare = DataHash( obj.kss{end}.observationModel.trainingParameters, struct( 'Method', {'SHA-512'} ) );
            obj.od.params.noCompare = obj.kss{end}.observationModel.trainingParameters;
            fprintf( '.\n' );
        end
        %% -------------------------------------------------------------------------------
        
        function procBlock = preproc( obj, blockAnnotations )
            procBlock = true;
            obj.azmsGroundTruth = blockAnnotations.srcAzms;
            if isstruct( obj.azmsGroundTruth ) || size( obj.azmsGroundTruth, 1 ) > 1
                error( 'AMLTTP:procBinding:singleValueBlockAnnotationsNeeded', ...
                    'SegmentKsWrapper can only handle one azm value per source per block.' );
            end
            srcsGlobalRefEnergyMeanChannel = cellfun( ...
                                    @(c)(sum(10.^(c./10)) ./ 2 ), blockAnnotations.globalSrcEnergy );
            srcsGlobalRefEnergyMeanChannel_db = 10 * log10( srcsGlobalRefEnergyMeanChannel );
            srcsHaveEnergy = srcsGlobalRefEnergyMeanChannel_db >= obj.srcSegregateNrjThreshold;
            isDiffuseSrc = isnan( obj.azmsGroundTruth );
            srcsHaveEnergy(isDiffuseSrc) = [];
            obj.azmsGroundTruth(isDiffuseSrc) = [];
            obj.azmsGroundTruth = wrapTo180( obj.azmsGroundTruth );
            if any( srcsHaveEnergy )
                streamAzms = obj.azmsGroundTruth(srcsHaveEnergy);
                [~, ~, ia] = uniquetol( streamAzms, 2.5, 'DataScale', 1 );
                streamAzms = accumarray( ia, streamAzms, [], @mean )';
                nStreamsWithEnergy = numel( streamAzms );
            else
                streamAzms = 0;
                nStreamsWithEnergy = 0;
            end
            if ~obj.useNsrcsKs
                rndNbias = randi( obj.nsrcsRndPlusMinusBias*2 + 1 ) ...
                                                - obj.nsrcsRndPlusMinusBias - 1;
                if obj.isNsrcsFixed
                    setNstreams = max( 1, obj.nsrcsBias + rndNbias );
                else
                    setNstreams = max( 1, nStreamsWithEnergy + obj.nsrcsBias + rndNbias );
                end
                obj.segmentKs.setFixedNoSrcs( setNstreams );
            else
                obj.segmentKs.setFixedNoSrcs( [] );
            end
            if ~obj.useDnnLocKs
                if obj.isAzmFixedUniform
                    azmStep = round( 360 / setNstreams );
                    streamAzms = round( azmStep/2 ) : azmStep : 360;
                else
                    azmVar = obj.varAzmSigma * randn( size( streamAzms ) );
                    streamAzms = wrapTo180( streamAzms + azmVar );
                    setNstreamsDiff = setNstreams - numel( streamAzms );
                    if setNstreamsDiff > 0
                        streamAzms = [streamAzms 360*rand( 1, setNstreamsDiff )];
                    elseif setNstreamsDiff < 0
                        rndidxs = randperm( numel( streamAzms ) );
                        streamAzms(rndidxs(1:abs(setNstreamsDiff))) = [];
                    end
                end
                obj.segmentKs.setFixedAzimuths( wrapTo180( streamAzms ) );
            else
                obj.segmentKs.setFixedAzimuths( [] );
                warning( 'off', 'BBS:badBlockTimeRequest' );
            end
            obj.segmentKs.setBlocksize( blockAnnotations.blockOffset ...
                                                - blockAnnotations.blockOnset );
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj, afeData, blockAnnotations )
            segHypos = obj.bbs.blackboard.getLastData( 'segmentationHypotheses' );
            nStreams = numel( segHypos.data );
            nSrcs = numel( obj.azmsGroundTruth );
            streamAzms = repmat( wrapTo180( [segHypos.data.refAzm]' ), 1, nSrcs );
            srcAzms = repmat( wrapTo180( obj.azmsGroundTruth ), nStreams, 1 );
            streamSrcAzmDists = abs( wrapTo180( srcAzms - streamAzms ) );
            switch obj.segSrcAssignmentMethod
                case 'minPermutedDistance'
                    streamIdxs = [];
                    while numel( streamIdxs ) < nSrcs
                        streamIdxs = [streamIdxs 1:nStreams]; %#ok<AGROW>
                    end
                    distCombinations = nchoosek( streamIdxs, nSrcs );
                    distPermutations = [];
                    for ii = 1 : size( distCombinations, 1 )
                        distPermutations = [distPermutations; ...
                                            perms( distCombinations(ii,:) )]; %#ok<AGROW>
                    end
                    distPermutations = unique( distPermutations, 'rows' );
                    distances = zeros( size( distPermutations ) );
                    for tt = 1 : size( distPermutations, 2 )
                        distances(:,tt) = streamSrcAzmDists(distPermutations(:,tt),tt);
                    end
                    permutedDistances = sum( distances, 2 );
                    [~,minPermutedDistanceIdx] = min( permutedDistances );
                    streamSrcAssignment = distPermutations(minPermutedDistanceIdx,:);
                case 'minDistance'
                    [~,streamSrcAssignment] = min( streamSrcAzmDists, [], 1 );
            end                   
            for ss = 1 : nStreams
                segData = segHypos.data(ss);
                softmask = (segData.softMask) .^ obj.softMaskExponent;
                obj.out.afeBlocks{end+1,1} = SegmentIdentityKS.maskAFEData( ...
                                       afeData, softmask, segData.cfHz, segData.hopSize );
                softMaskSignal = struct( ...
                                   'FsHz', {1/segData.hopSize}, ...
                                   'Name', {'SoftMask'}, 'Label', {'SoftMask'}, ...
                                   'cfHz', {segData.cfHz}, ...
                                   'Dimensions', {'nSamples x nFilters'}, ...
                                   'Channel', {'mono'}, ...
                                   'Data', {segData.softMask} );
                softMaskSignalKey = max( cell2mat( obj.out.afeBlocks{end,1}.keys ) ) + 1;               
                obj.out.afeBlocks{end,1}(softMaskSignalKey) = softMaskSignal;
                thisStreamSrcIdxs = find( streamSrcAssignment == ss );
                maskedBlockAnnotations = obj.maskBA( blockAnnotations, thisStreamSrcIdxs );  %#ok<FNDSB>
                maskedBlockAnnotations.estAzm = segData.refAzm;
                maskedBlockAnnotations.nStreams = nStreams;
                if isempty(obj.out.blockAnnotations)
                    obj.out.blockAnnotations = maskedBlockAnnotations;
                else
                    obj.out.blockAnnotations(end+1,1) = maskedBlockAnnotations;
                end
            end
            warning( 'on', 'BBS:badBlockTimeRequest' );
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getKsInternOutputDependencies( obj )
            outputDeps.v = 17;
            outputDeps.useDnnLocKs = obj.useDnnLocKs;
            outputDeps.useNsrcsKs = obj.useNsrcsKs;
            outputDeps.useIdModels = ~isempty( obj.idKss );
            outputDeps.params = obj.od.params.compare;
            outputDeps.noCompare = obj.od.params.noCompare;
            [~,outputDeps.afeHashs] = obj.getAfeRequests();
            outputDeps.varAzmSigma = obj.varAzmSigma;
            outputDeps.segSrcAssignmentMethod = obj.segSrcAssignmentMethod;
            outputDeps.nsrcsBias = obj.nsrcsBias;
            outputDeps.nsrcsRndPlusMinusBias = obj.nsrcsRndPlusMinusBias;
            outputDeps.softMaskExponent = obj.softMaskExponent;
            outputDeps.srcSegregateNrjThreshold = obj.srcSegregateNrjThreshold;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        %% -------------------------------------------------------------------------------
        
        function blockAnnotations = maskBA( ~, blockAnnotations, srcIdxs )
            rSrcIdxs = 1:max( srcIdxs );
            rSrcIdxs(srcIdxs) = 1:numel(srcIdxs);
            baFields = fieldnames( blockAnnotations );
            meBaf = strcmpi( 'mixEnergy', baFields );
            ffs = 1 : numel( baFields );
            ffs(meBaf) = [];
            for ff = ffs
                if isstruct( blockAnnotations.(baFields{ff}) )
                    baSrcs = cell2mat( blockAnnotations.(baFields{ff}).(baFields{ff})(:,2) );
                    baIsSrcIdEq = false( size( baSrcs ) );
                    for ii = 1 : numel( baSrcs )
                        baIsSrcIdEq(ii) = any( baSrcs(ii) == srcIdxs );
                    end
                    blockAnnotations.(baFields{ff}).t.onset = ...
                                     blockAnnotations.(baFields{ff}).t.onset(baIsSrcIdEq);
                    blockAnnotations.(baFields{ff}).t.offset = ...
                                     blockAnnotations.(baFields{ff}).t.offset(baIsSrcIdEq);
                    blockAnnotations.(baFields{ff}).(baFields{ff}) = ...
                            blockAnnotations.(baFields{ff}).(baFields{ff})(baIsSrcIdEq,:);
                    blockAnnotations.(baFields{ff}).(baFields{ff})(:,2) = ...
                                                           cellfun( @(x)(rSrcIdxs(x)), ...
                                  blockAnnotations.(baFields{ff}).(baFields{ff})(:,2), ...
                                                                 'UniformOutput', false );
                elseif iscell( blockAnnotations.(baFields{ff}) ) ...
                       || (numel( blockAnnotations.(baFields{ff}) ) > 1)
                    baIsSrcIdEq = false( size( blockAnnotations.(baFields{ff}) ) );
                    baIsSrcIdEq(srcIdxs) = true;
                    blockAnnotations.(baFields{ff}) = ...
                                             blockAnnotations.(baFields{ff})(baIsSrcIdEq);
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

