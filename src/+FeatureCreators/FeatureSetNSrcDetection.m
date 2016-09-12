classdef FeatureSetNSrcDetection < FeatureCreators.Base
    % FeatureSetNSrc   Number of Sources estimation with features consisting ok:
    %     DUET, ILD, ITD, Onset Str., Offset Str.
    
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
            obj.maxDelaySec = 0.0011;
            obj.maxOffsetDB = 30;
        end
        
        function afeRequests = getAFErequests( obj )
            params = genParStruct(...
                'cc_wSizeSec', obj.wSizeSec,...
                'cc_hSizeSec', obj.hSizeSec,...
                'cc_maxDelaySec', obj.maxDelaySec,...
                'fb_type', 'gammatone',...
                'fb_lowFreqHz', 80,...
                'fb_highFreqHz', 8000,...
                'fb_nChannels', obj.nFreqChannels,...
                'ihc_method', 'halfwave',...
                'ild_wSizeSec', obj.wSizeSec,...
                'ild_hSizeSec', obj.hSizeSec,...
                'ons_maxOffsetdB', obj.maxOffsetDB,...
                'ofs_maxOffsetdB', obj.maxOffsetDB,...
                'stft_wSizeSec', obj.wSizeSec,...
                'stft_hSizeSec', obj.hSizeSec);
            
            % stft
            afeRequests{1}.name = 'stft';
            afeRequests{1}.params = params;
            
            % internaural level differences
            afeRequests{2}.name = 'ild';
            afeRequests{2}.params = params;
            
            % internaural time differences
            afeRequests{3}.name = 'itd';
            afeRequests{3}.params = params;
            
            % onset strengths
            afeRequests{4}.name = 'onsetStrength';
            afeRequests{4}.params = params;
            
            % offset strengths
            afeRequests{5}.name = 'offsetStrength';
            afeRequests{5}.params = params;
            
        end
        
        function x = constructVector( obj )
            % constructVector from afe requests
            %   #1: DUET |-, #2: ILD, #3: ITD, #4: OnS, #5: OfS
            %
            %   See getAFErequests
            
            % afeIdx 1: STFT -> DUET histogram
            stft_l = obj.makeBlockFromAfe( 1, 1, @(a)(a.Data), []);
            stft_r = obj.makeBlockFromAfe( 1, 2,  @(a)(a.Data), []);
            duet_block = obj.createDuetFeature(stft_l{1}, stft_r{1});
            x = obj.reshape2featVec( duet_block );
            
            % afeIdx 2: ILD
            ild = obj.makeBlockFromAfe( 2, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            x = obj.concatFeats( x, obj.reshape2featVec( ild ) );
            
            % afeIdx 3: ITD
            itd = obj.makeBlockFromAfe( 3, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            x = obj.concatFeats( x, obj.reshape2featVec( itd ) );
            
            % afeIdx 4: onset strengths
            itd = obj.makeBlockFromAfe( 4, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            x = obj.concatFeats( x, obj.reshape2featVec( itd ) );
            
            % afeIdx 5: offset strengths
            itd = obj.makeBlockFromAfe( 5, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            x = obj.concatFeats( x, obj.reshape2featVec( itd ) );

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
            outputDeps.v = 24;
        end
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
        
        function rval = createDuetFeature(tfL, tfR, maxAlpha, maxDelta, binsAlpha, binsDelta, preproc)
            %createDuetFeature   builds a duet histogram over the block
            
            % init, default parameters from [1]
            if nargin < 2
                error('method needs at least two mixtures as input!');
            end
            if nargin < 3
                maxAlpha = 0.7;
            end
            if nargin < 4
                maxDelta = 3.6;
            end
            if nargin < 5
                binsAlpha = 51;
            end
            if nargin < 6
                binsDelta = 51;
            end
            if nargin < 7
                preproc = {'noDC'};
            end
            
            % init and preprocess tf data
            [nFrames, nFFT] = size(tfL);
            freq = [ (0:nFFT/2) ((-nFFT/2)+1:-1) ] * (2*pi/nFFT);
            if any(cellfun(@(a)(any(a)), arrayfun(@(a)(strfind(a,'positive')),preproc)))
                tfL(:,nFFT/2+1:end) = [];
                tfR(:,nFFT/2+1:end) = [];
                freq(nFFT/2+1:end) = [];
            end
            if any(cellfun(@(a)(any(a)), arrayfun(@(a)(strfind(a,'noDC')),preproc)))
                tfL(:,1) = [];
                tfR(:,1) = [];
                freq(1) = [];
            end
            fmat = freq(ones(nFrames,1),:);
            
            % DUET: estimation of alpha and delta using 
            tfRL = (tfR + eps)./(tfL + eps);
            alpha = abs(tfRL) - 1./abs(tfRL);
            delta = -imag(log(tfRL))./fmat;
            
            % DUET: calculate weighted histogram
            % weighting powers according ot [1]
            % p=0; q=0; % simple counting
            % p=1; q=0; % more symetric attenuation
            % p=1; q=2; % more delay
            % p=2; q=0; % reducing bias on the delay estimator
            % p=2; q=2; % low SRN and speech mixtures
            % we settle for p=2 and q=0
            p=2; q=0;
            tfWeight = (abs(tfL).*abs(tfR)).^p.*abs(fmat).^q; %weights vector
            
            % mask tf-points yielding estimates in bounds
            mask = (abs(alpha)<maxAlpha) & (abs(delta)<maxDelta);
            vecAlpha = alpha(mask);
            vecDelta = delta(mask);
            tfWeight = tfWeight(mask);
            
            % determine histogram indices
            idxAlpha = round(1+(binsAlpha-1)*(vecAlpha+maxAlpha)/(2*maxAlpha));
            idxDelta = round(1+(binsDelta-1)*(vecDelta+maxDelta)/(2*maxDelta));

            % full sparse trick to create 2d weighted & smoothed histogram
            duet_hist_raw = full(sparse(idxAlpha,idxDelta,tfWeight,binsAlpha,binsDelta));
            % condensing the feature information into a 11x11 matrix
            %duet_hist = conv2(duet_hist, ones(3,3)/3^2, 'same');
            duet_hist = downsample(duet_hist_raw, 5)';
            duet_hist = downsample(duet_hist, 5)';
            % 11x11 matrix should still contain the peak information if it
            % was meaningfull.            
            
            % debug: to watch the histogram
            % surf(linspace(-maxDelta,maxDelta,binsDelta),linspace(-maxAlpha,maxAlpha,binsAlpha),duet_hist);
            
            % build block and return
            grpInfo = {'duet_hist', '11x11-hist', 'stereo'};
            alphaAxisVal = arrayfun(@(a)(num2str(a)),linspace(-maxAlpha, maxAlpha, 11),'UniformOutput',false);
            deltaAxisVal = arrayfun(@(a)(num2str(a)),linspace(-maxDelta, maxDelta, 11),'UniformOutput',false);
            for ii = 1:11
                alphaInfo{ii} = {grpInfo{:}, alphaAxisVal{ii}};
            end
            for ii = 1:11
                deltaInfo{ii} = {grpInfo{:}, deltaAxisVal{ii}};
            end            
            rval = { duet_hist, alphaInfo, deltaInfo };
  
        end
        
    end
    
end
