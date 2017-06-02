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
        energeticBaidxs;
        nsrcsBias;
        nsrcsRndPlusMinusBias;
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
            obj.energeticBaidxs = [];
            obj.nsrcsBias = ip.Results.nsrcsBias;
            if obj.useNsrcsKs && (obj.nsrcsBias ~= 0)
                error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                       ['nSrcs bias only supported if using ' ...
                        'nSrcs ground truth.'] );
            end
            obj.nsrcsRndPlusMinusBias = ip.Results.nsrcsRndPlusMinusBias;
            if obj.useNsrcsKs && (obj.nsrcsRndPlusMinusBias ~= 0)
                error( 'AMLTTP:usage:unsupportedOptionSetting', ...
                       ['nSrcs random bias only supported if using ' ...
                        'nSrcs ground truth.'] );
            end
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
            srcsHaveEnergy = cellfun( @(se)(any(se > -40)), blockAnnotations.srcEnergy );
            obj.energeticBaidxs = 1 : numel( blockAnnotations.srcEnergy );
            if any( srcsHaveEnergy )
                obj.azmsGroundTruth(~srcsHaveEnergy) = [];
                obj.energeticBaidxs(~srcsHaveEnergy) = [];
            % else
                % do nothing, because if no src is assumed, we still want
                % to analyze the full stream. Never segregate into "zero"
                % streams.
            end
            obj.energeticBaidxs(isnan(obj.azmsGroundTruth)) = [];
            obj.azmsGroundTruth(isnan(obj.azmsGroundTruth)) = [];
            if isempty( obj.azmsGroundTruth )
                procBlock = false;
                return;
            end
            if ~obj.useNsrcsKs
                rndNbias = randi( obj.nsrcsRndPlusMinusBias*2 + 1 ) ...
                                           * (obj.nsrcsRndPlusMinusBias > 0 )...
                                                - obj.nsrcsRndPlusMinusBias - 1;
                setNsrcs = max( 1, sum( srcsHaveEnergy ) ...
                                   + obj.nsrcsBias + rndNbias );
                obj.segmentKs.setFixedNoSrcs( setNsrcs );
            else
                obj.segmentKs.setFixedNoSrcs( [] );
            end
            if ~obj.useDnnLocKs
                azmVar = obj.varAzmSigma * randn( size( obj.azmsGroundTruth ) );
                currentVarAzms = wrapTo180( obj.azmsGroundTruth + azmVar );
                if sum( srcsHaveEnergy ) == 0
                    rndidxs = randperm( numel( currentVarAzms ) );
                    currentVarAzms = currentVarAzms(rndidxs(1:setNsrcs));
                else
                    setNsrcsDiff = setNsrcs - numel( currentVarAzms );
                    if setNsrcsDiff > 0
                        currentVarAzms = [currentVarAzms ...
                                          360 * rand( 1, setNsrcsDiff )];
                    elseif setNsrcsDiff < 0
                        rndidxs = randperm( numel( currentVarAzms ) );
                        currentVarAzms(rndidxs(1:abs(setNsrcsDiff))) = [];
                    end
                end
                obj.segmentKs.setFixedAzimuths( wrapTo180( currentVarAzms ) );
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
            nSegments = numel( segHypos.data );
            nTrue = numel( obj.azmsGroundTruth );
            hypAzms = repmat( wrapTo180( [segHypos.data.refAzm]' ), 1, nTrue );
            gtAzms = repmat( wrapTo180( obj.azmsGroundTruth ), nSegments, 1 );
            hypAzmGtDists = abs( wrapTo180( gtAzms - hypAzms ) );
            switch obj.segSrcAssignmentMethod
                case 'minPermutedDistance'
                    segIdxs = [];
                    while numel( segIdxs ) < nTrue
                        segIdxs = [segIdxs 1:nSegments]; %#ok<AGROW>
                    end
                    distCombinations = nchoosek( segIdxs, nTrue );
                    distPermutations = [];
                    for ii = 1 : size( distCombinations, 1 )
                        distPermutations = [distPermutations; ...
                                            perms( distCombinations(ii,:) )]; %#ok<AGROW>
                    end
                    distPermutations = unique( distPermutations, 'rows' );
                    distances = zeros( size( distPermutations ) );
                    permutedDistances = zeros( size( distPermutations, 1 ), 1 );
                    for ss = 1 : size( distPermutations, 1 )
                        for tt = 1 : size( distPermutations, 2 )
                            distances(ss,tt) = hypAzmGtDists(distPermutations(ss,tt),tt);
                        end
                        permutedDistances(ss) = sum( distances(ss,:) );
                    end
                    [~,minPermutedDistanceIdx] = min( permutedDistances );
                    segSrcAssignment = distPermutations(minPermutedDistanceIdx,:);
                case 'minDistance'
                    [~,segSrcAssignment] = min( hypAzmGtDists, [], 1 );
            end                   
            for ss = 1 : nSegments
                obj.out.afeBlocks{end+1,1} = obj.softmaskAFE( afeData, segHypos, ss );
                srcIdxs = find( segSrcAssignment == ss );
                srcIdxs = obj.energeticBaidxs(srcIdxs); %#ok<FNDSB>
                maskedBlockAnnotations = obj.maskBA( blockAnnotations, srcIdxs ); 
                maskedBlockAnnotations.estAzm = segHypos.data(ss).refAzm;
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
            outputDeps.v = 12;
            outputDeps.useDnnLocKs = obj.useDnnLocKs;
            outputDeps.useNsrcsKs = obj.useNsrcsKs;
            outputDeps.useIdModels = ~isempty( obj.idKss );
            outputDeps.params = obj.kss{end}.observationModel.trainingParameters;
            [~,outputDeps.afeHashs] = obj.getAfeRequests();
            outputDeps.varAzmSigma = obj.varAzmSigma;
            outputDeps.segSrcAssignmentMethod = obj.segSrcAssignmentMethod;
            outputDeps.nsrcsBias = obj.nsrcsBias;
            outputDeps.nsrcsRndPlusMinusBias = obj.nsrcsRndPlusMinusBias;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        %% -------------------------------------------------------------------------------
        
        function afeBlock = softmaskAFE( ~, afeBlock, segHypos, idx_mask )
            afeBlock = SegmentIdentityKS.maskAFEData( afeBlock, ...
                                                      segHypos.data(idx_mask).softMask, ...
                                                      segHypos.data(idx_mask).cfHz, ...
                                                      segHypos.data(idx_mask).hopSize );
        end
        %% -------------------------------------------------------------------------------
        
        function blockAnnotations = maskBA( ~, blockAnnotations, srcIdxs )
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

        

