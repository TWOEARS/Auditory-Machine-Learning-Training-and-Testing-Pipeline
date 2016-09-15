classdef FeatureSetNSrcDetection < FeatureCreators.Base
% FeatureSetNSrc   Number of Sources estimation with features consisting ok:
%     DUET, ILD, ITD, Onset Str., Offset Str.
%
% DUET is a binaural blind source seperation algorithm based on a histogram
% of differences in level and phase of the time-frequency representation of
% the mixture signals. We only use the histogram in delta-level-delta-phase
% space and attribute clear peaks to individual sources. This method
% relies on the W-disjunct orthogonality of the sources (e.g. only one
% source is active per time-frequency bin). This is assumption is (mildly)
% violated for echoic mixtures.
%
% [1] Rickard, S. (2007). The DUET Blind Source Separation Algorithm.
%     In S. Makino, H. Sawada, & T.-W. Lee (Eds.),
%     Blind Speech Separation (pp. 217–241). inbook,
%     Dordrecht: Springer Netherlands.
%     http://doi.org/10.1007/978-1-4020-6479-1_8
%
    
    %% PROPERTIES
    
    properties (SetAccess = private)
        nFreqChannels;  % # of frequency channels
        wSizeSec;       % window size in seconds
        hSizeSec;       % window step size in seconds
        maxDelaySec;    % maximum cross-correleation delay
        maxOffsetDB;    % offset for the onset/offset features on dB
    end
    
    %% METHODS
    
    methods (Access = public)
        
        function obj = FeatureSetNSrcDetection( )
            obj = obj@FeatureCreators.Base();
            obj.nFreqChannels = 16;
            obj.wSizeSec = 0.02;
            obj.hSizeSec = 0.01;
            obj.maxDelaySec = 0.001;
            obj.maxOffsetDB = 30;
        end
        
        function afeRequests = getAFErequests( obj )
            % stft
            afeRequests{1}.name = 'stft';
            afeRequests{1}.params = genParStruct( ...
                'fb_type', 'gammatone',...
                'fb_lowFreqHz', 80,...
                'fb_highFreqHz', 8000,...
                'fb_nChannels', obj.nFreqChannels,...
                'stft_wSizeSec', obj.wSizeSec,...
                'stft_hSizeSec', obj.hSizeSec...
                );
            
            % internaural level differences
            afeRequests{2}.name = 'ild';
            afeRequests{2}.params = genParStruct( ...
                'fb_type', 'gammatone',...
                'fb_nChannels', obj.nFreqChannels,...
                'ihc_method', 'halfwave',...
                'ild_wSizeSec', obj.wSizeSec,...
                'ild_hSizeSec', obj.hSizeSec...
                );
            
            % internaural time differences
            afeRequests{3}.name = 'itd';
            afeRequests{3}.params = genParStruct( ...
                'cc_wSizeSec', obj.wSizeSec,...
                'cc_hSizeSec', obj.hSizeSec,...
                'cc_maxDelaySec', obj.maxDelaySec,...
                'ihc_method', 'dau',...
                'fb_type', 'gammatone',...
                'fb_nChannels', obj.nFreqChannels...
                );
            
            % onset strengths
            afeRequests{4}.name = 'onsetStrength';
            afeRequests{4}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'ons_maxOffsetdB', obj.maxOffsetDB,...
                'ofs_maxOffsetdB', obj.maxOffsetDB,...
                'fb_nChannels', obj.nFreqChannels ...
                );

            % spectral statistics
            afeRequests{5}.name = 'spectralFeatures';
            afeRequests{5}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.nFreqChannels ...
                );
        end
        
        function x = constructVector( obj )
            % constructVector from afe requests
            %   #1: DUET, #2: ILD, #3: ITD, #4: OnS
            %
            %   See getAFErequests
            
            % afeIdx 1: STFT -> DUET histogram & summary
            stft_l = obj.makeBlockFromAfe( 1, 1, @(a)(a.Data), []);
            stft_r = obj.makeBlockFromAfe( 1, 2, @(a)(a.Data), []);
            duet_blocks = obj.createDuetFeatureBlocks(...
                stft_l{1}, stft_r{1},...
                3, ~obj.descriptionBuilt);
            % duet histogram in sym. attenuation / phase space
            x = obj.reshape2featVec( duet_blocks{1} );
            % duet histogram summary featues
            x = obj.concatFeats( x, duet_blocks{2} );
            
            % afeIdx 2: ILD
            ild = obj.makeBlockFromAfe( 2, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            ildLM = obj.block2feat(...
                ild,...
                @(b)(lMomentAlongDim( b, [1,2,3,4], 1, true )),...
                2,...
                @(idxs)(sort([idxs idxs idxs idxs])),...
                {{'1.LMom',@(idxs)(idxs(1:4:end))},...
                 {'2.LMom',@(idxs)(idxs(2:4:end))},...
                 {'3.LMom',@(idxs)(idxs(3:4:end))},...
                 {'4.LMom',@(idxs)(idxs(4:4:end))}} ); 
            x = obj.concatFeats( x, ildLM );
            
            % afeIdx 3: ITD
            itd = obj.makeBlockFromAfe( 3, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            itdLM = obj.block2feat(...
                itd,...
                @(b)(lMomentAlongDim( b, [1,2,3,4], 1, true )),...
                2,...
                @(idxs)(sort([idxs idxs idxs idxs])),...
                {{'1.LMom',@(idxs)(idxs(1:4:end))},...
                 {'2.LMom',@(idxs)(idxs(2:4:end))},...
                 {'3.LMom',@(idxs)(idxs(3:4:end))},...
                 {'4.LMom',@(idxs)(idxs(4:4:end))}} ); 
            x = obj.concatFeats( x, itdLM );
            
            % afeIdx 4: onsetStrengths (same as in FeatureSet1Blockmean)
            onsR = obj.makeBlockFromAfe( 4, 1,...
                @(a)(compressAndScale( a.Data, 0.33 )),...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)},...
                {'t'},...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
            onsL = obj.makeBlockFromAfe( 4, 2,...
                @(a)(compressAndScale( a.Data, 0.33 )),...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)},...
                {'t'},...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
            ons = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', onsR, onsL );
            onsLm = obj.block2feat(...
                ons,...
                @(b)(lMomentAlongDim( b, [1,2,3,4], 1, true )),...
                2,...
                @(idxs)(sort([idxs idxs idxs idxs])),...
                {{'1.LMom',@(idxs)(idxs(1:4:end))},...
                 {'2.LMom',@(idxs)(idxs(2:4:end))},...
                 {'3.LMom',@(idxs)(idxs(3:4:end))},...
                 {'4.LMom',@(idxs)(idxs(4:4:end))}} );
             x = obj.concatFeats( x, onsLm );
             
        end
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            % relevant members
            outputDeps.nFreqChannels = obj.nFreqChannels;
            outputDeps.wSizeSec = obj.wSizeSec;
            outputDeps.hSizeSec = obj.hSizeSec;
            outputDeps.maxDelaySec = obj.maxDelaySec;
            outputDeps.maxOffsetDB = obj.maxOffsetDB;
            % classname
            classInfo = metaclass( obj );
            classnames = strsplit( classInfo.Name, '.' );
            outputDeps.featureProc = classnames{end};
            % version
            outputDeps.v = 28;
        end
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
        
        function rval = createDuetFeatureBlocks(...
                tfL, tfR,...
                sampleFactor, requestDescription,...
                maxAlpha, maxDelta, binsAlpha, binsDelta,...
                preproc)
            %createDuetFeatureBlocks   builds a duet histogram over the block
            %   returns the weighted, smoothed histogram and a summary of
            %   its moments and peak spectrum in seperate blocks
            
            % init
            if nargin < 2
                error('method needs at least the two time-frequency mixtures as input!');
            end
            if nargin < 3
                sampleFactor = 1;
            end
            if nargin < 4
                requestDescription = false;
            end
            % default parameters from [1]
            if nargin < 5
                maxAlpha = 0.7;
            end
            if nargin < 6
                maxDelta = 3.6;
            end
            if nargin < 7
                binsAlpha = 35;
            end
            if nargin < 8
                binsDelta = 51;
            end
            if nargin < 9
                preproc = {'noDC'};
%                 preproc = {'noDC','noSymmetry'};
            end
            
            % preprocess tf data
            [nFrames, nFFT] = size(tfL);
            freqInfo = [ (0:nFFT/2) ((-nFFT/2)+1:-1) ] * (2*pi/nFFT);
            if any(cellfun(@(a)(any(a)), arrayfun(@(a)(strfind(a,'noSymmetry')),preproc)))
                tfL(:,nFFT/2+1:end) = [];
                tfR(:,nFFT/2+1:end) = [];
                freqInfo(nFFT/2+1:end) = [];
            end
            if any(cellfun(@(a)(any(a)), arrayfun(@(a)(strfind(a,'noDC')),preproc)))
                tfL(:,1) = [];
                tfR(:,1) = [];
                freqInfo(1) = [];
            end
            fmat = freqInfo(ones(nFrames,1),:);
            
            % DUET: estimation of alpha (power) and delta (delay) mixture parameters
            tfRL = (tfR + eps)./(tfL + eps);
            % following projection is called symmetric attenuation in [1]
            alpha = abs(tfRL) - 1./abs(tfRL);
            % positive alpha means more power on the R channel
            % negative alpha means more power on the L channel
            delta = -imag(log(tfRL))./fmat;
            % delta is the phase difference in radiants, means R phase earlier than L
            % negative delta means L phase earlier than R
            
            % DUET: calculate weighted histogram
            % weighting powers according to [1]
            % p=0; q=0; % simple counting
            % p=1; q=0; % only symetric attenuation
            % p=1; q=2; % emphasis on delays
            % p=2; q=0; % reducing bias on the delay estimator
            % p=2; q=2; % low SRN and speech mixtures
            % we settle for p=2 and q=0
            p=2; q=2;
            tfWeight = (abs(tfL).*abs(tfR)).^p.*abs(fmat).^q; % weights vector
            % mask tf-points yielding estimates in bounds
            mask = (abs(alpha)<maxAlpha) & (abs(delta)<maxDelta);
            vecAlpha = alpha(mask);
            vecDelta = delta(mask);
            tfWeight = tfWeight(mask);            
            % determine histogram indices
            idxAlpha = round(1+(binsAlpha-1)*(vecAlpha+maxAlpha)/(2*maxAlpha));
            idxDelta = round(1+(binsDelta-1)*(vecDelta+maxDelta)/(2*maxDelta));
            % full sparse trick to create 2d weighted histogram
            duet_hist_raw = full(sparse(idxAlpha, idxDelta, tfWeight, binsAlpha, binsDelta));
            
            % salvitzky-golay smoothing filter
            duet_hist = sgolayfilt(duet_hist_raw, 3, 5);
            duet_hist = sgolayfilt(duet_hist', 3, 5)';
            % down sampling
            if sampleFactor ~= 1
                duet_hist = resample(duet_hist, 1, sampleFactor, 1);
                duet_hist = resample(duet_hist', 1, sampleFactor, 1)';
                [binsAlpha, binsDelta] = size(duet_hist);
            end
            % cut filter artifacts and use max scaling
            duet_hist(duet_hist < 0) = 0;
            duet_hist_max = max(max(duet_hist));
            duet_hist = duet_hist ./ duet_hist_max;
            block_hist = { duet_hist };
            
            % the smothed and max-scaled histogram should contain the peak information
            % in accessible form. main problem here is that the peaks are transient
            % and we have to find a way to project them onto stationary features.
            
            % debug: to watch the histogram
            % surf(linspace(-maxDelta,maxDelta,binsDelta),linspace(-maxAlpha,maxAlpha,binsAlpha),duet_hist);
            
            if requestDescription
                % build histogram block description
                histGrpInfo = {'duet_hist', [num2str(binsAlpha) 'x' num2str(binsDelta) '-hist'], 'mono'};
                alphaAxisVal = arrayfun(@(a)(['a' num2str(a)]),linspace(-maxAlpha, maxAlpha, binsAlpha),'UniformOutput',false);
                deltaAxisVal = arrayfun(@(a)(['d' num2str(a)]),linspace(-maxDelta, maxDelta, binsDelta),'UniformOutput',false);
                for ii = 1:binsAlpha
                    alphaInfo{ii} = { histGrpInfo{:}, alphaAxisVal{ii} };
                end
                for ii = 1:binsDelta
                    deltaInfo{ii} = { histGrpInfo{:}, deltaAxisVal{ii} };
                end
                block_hist = { duet_hist, alphaInfo, deltaInfo };
            end
            
            % build summary block
            idx = 1;
            summaryData(idx) = duet_hist_max;
            if requestDescription
                summaryGrpInfo = {'duet_summary', '1x15', 'stereo'};
                summaryInfo{1} = {summaryGrpInfo{:}, 'abs_max_peak'};
            end
            
            histPeaks = extrema2(duet_hist);
            for ii = 1:10
                try
                    summaryData(idx+ii) = histPeaks(ii);
                catch
                    % pass
                end
                if requestDescription
                    summaryInfo{idx+ii} = {summaryGrpInfo{:}, ['peak' num2str(ii)]};
                end
            end
            idx = idx + ii;
            
            duet_hist_flat = reshape(duet_hist, numel(duet_hist), 1);
            for ii = 1:4
                try
                    summaryData(idx+ii) = lMoments(duet_hist_flat, ii);
                catch
                    % pass
                end
                if requestDescription
                    summaryInfo{idx+ii} = {summaryGrpInfo{:}, ['lmom' num2str(ii)]};
                end
            end
            block_summary = { summaryData };
            if requestDescription
                block_summary = { summaryData, summaryInfo };
            end
            
            % return both blocks
            rval = { block_hist, block_summary };
  
        end
        
    end
    
end
