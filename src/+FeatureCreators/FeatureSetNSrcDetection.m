classdef FeatureSetNSrcDetection < FeatureCreators.Base
% FeatureSetNSrc   Number of Sources estimation with features consisting of:
%     DUET, ILD, ITD, Onset Str.
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
    
    properties (SetAccess = protected)
        nFreqChannels;  % # of frequency channels
        wSizeSec;       % window size in seconds
        hSizeSec;       % window step size in seconds
        maxDelaySec;    % maximum cross-correleation delay
        maxOffsetDB;    % offset for the onset/offset features on dB
        duetIntegrate;  % will integrate duet features over the whole block
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
            obj.duetIntegrate = true;
        end
        
        function afeRequests = getAFErequests( obj )
            % duet
            % wSTFTSec;   % window size in seconds for STFT
            % wDUETSec;   % window size in seconds for DUET histogram
            % hDUETSec;   % window shift for duet historgram
            % binsAlpha;  % number of histogram bins for alpha dimension
            % binsDelta;  % number of histogram bins for delta dimension
            % maxAlpha;   % masking threshold for alpha dimension
            % maxDelta;   % masking threshold for delta dimension
            afeRequests{1}.name = 'duet';
            afeRequests{1}.params = genParStruct( ...
                'duet_wSTFTSec', obj.wSizeSec,...
                'duet_wDUETSec', (1/2),...
                'duet_hDUETSec', (1/6));
            
            % internaural level differences
            afeRequests{2}.name = 'ild';
            afeRequests{2}.params = genParStruct( ...
                'fb_type', 'gammatone',...
                'fb_nChannels', obj.nFreqChannels,...
                'ihc_method', 'halfwave',... % why is this different for itd and ild?
                'ild_wSizeSec', obj.wSizeSec,...
                'ild_hSizeSec', obj.hSizeSec);
            
            % internaural time differences
            afeRequests{3}.name = 'itd';
            afeRequests{3}.params = genParStruct( ...
                'cc_wSizeSec', obj.wSizeSec,...
                'cc_hSizeSec', obj.hSizeSec,...
                'cc_maxDelaySec', obj.maxDelaySec,...
                'pp_bMiddleEarFiltering', true,...
                'pp_bNormalizeRMS', true,...
                'ihc_method', 'dau',... % why is this different for itd and ild?
                'fb_type', 'gammatone',...
                'fb_nChannels', obj.nFreqChannels);
            
            % onset strengths
            afeRequests{4}.name = 'onsetStrength';
            afeRequests{4}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'ons_maxOffsetdB', obj.maxOffsetDB,...
                'ofs_maxOffsetdB', obj.maxOffsetDB,...
                'fb_nChannels', obj.nFreqChannels);

            % spectral statistics
            afeRequests{5}.name = 'spectralFeatures';
            afeRequests{5}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.nFreqChannels);
        end
        
        function x = constructVector( obj )
            % constructVector from afe requests
            %   #1: DUET, #2: ILD, #3: ITD, #4: OnS
            %
            %   See getAFErequests
            
            % afeIdx 1: STFT -> DUET histogram & summary
            duet = obj.afeData(1);
            duet_blocks = obj.makeDuetFeatureBlocks(...
                duet{1},...
                ~obj.descriptionBuilt,...
                obj.duetIntegrate);
            % duet histogram in sym. attenuation / phase space
            duet_hist = obj.reshapeBlock( duet_blocks{1}, 1 );
            duet_hist = obj.reshape2featVec( duet_hist );
            % duet histogram summary featues
            duet_summ = obj.reshape2featVec( duet_blocks{2} );
            x = obj.concatFeats( duet_hist, duet_summ );
            
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
            outputDeps.duetIntegrate = obj.duetIntegrate;
            % classname
            classInfo = metaclass( obj );
            classnames = strsplit( classInfo.Name, '.' );
            outputDeps.featureProc = classnames{end};
            % version
            outputDeps.v = 32;
        end
        
    end
    
    %% STATIC METHODS
    
    methods (Static)
        
        function rval = makeDuetFeatureBlocks(sig, request_description, do_integration)
            %createDuetFeatureBlocks   creates valid blocks with description (optional)
            %   firsst block is a time series of histograms
            %   second block is a time series of peak-spectrum and moments of the histogram
            %
            % INPUTS:
            %   duet                : histogram input
            %   requestDescription  : if true, build block annotations
            %   do_integration      : if true, integrate the stream in to one histogram
            %
            
            % init
            if nargin < 1
                error('method needs at least the histogram as input!');
            end
            if nargin < 2
                request_description = false;
            end
            if nargin < 3
                do_integration = false;
            end
            if iscell(sig)
                sig = sig{1};
            end
            data = sig.Data;
            nFrames = size(data, 1);
            
            % build histgram block
            if do_integration
                data = mean(data,1);
                nFrames = 1;
            end
            block_hist = { data };
            if request_description
                % build histogram block description
                histGrpInfo = {'duet_hist',...
                               [num2str(nFrames) 'x' ...
                                num2str(sig.binsAlpha) 'x' ...
                                num2str(sig.binsDelta) '-hist'],...
                               'mono'};
                timeAxisVal = arrayfun(@(a)(['t' num2str(a)]),1:nFrames,'UniformOutput',false);
                alphaAxisVal = arrayfun(@(a)(['a' num2str(a)]),linspace(-sig.maxAlpha, sig.maxAlpha, sig.binsAlpha),'UniformOutput',false);
                deltaAxisVal = arrayfun(@(a)(['d' num2str(a)]),linspace(-sig.maxDelta, sig.maxDelta, sig.binsDelta),'UniformOutput',false);
                for ii = 1:nFrames
                    timeInfo{ii} = { histGrpInfo{:}, timeAxisVal{ii} };
                end
                for ii = 1:sig.binsAlpha
                    alphaInfo{ii} = { histGrpInfo{:}, alphaAxisVal{ii} };
                end
                for ii = 1:sig.binsDelta
                    deltaInfo{ii} = { histGrpInfo{:}, deltaAxisVal{ii} };
                end
                block_hist = { block_hist{:}, timeInfo, alphaInfo, deltaInfo };
            end
            
            % build summary block
            summaryData = zeros(nFrames, 14);
            for ff = 1:nFrames
                frame_data = squeeze(data(ff,:,:));
                try
                    frame_peaks = extrema2(frame_data);
                catch
                    frame_peaks = zeros(1,10);
                end
                for ii = 1:min(10,numel(frame_peaks))
                    try
                        summaryData(ff,ii) = frame_peaks(ii);
                    catch
                        % pass
                    end
                end
                frame_data_flat = reshape(frame_data, numel(frame_data), 1);
                for ii = 1:4
                    try
                        summaryData(ff,10+ii) = lMoments(frame_data_flat, ii);
                    catch
                        % pass
                    end
                end
            end
            block_summary = { summaryData };
            if request_description
                % build summary block desctiption
                summaryGrpInfo = {'duet_summary', [nFrames 'x14'], 'mono'};
                for ii = 1:10
                    summaryInfo{ii} = {summaryGrpInfo{:}, ['peak' num2str(ii)]};
                end
                for ii = 1:4
                    summaryInfo{10+ii} = {summaryGrpInfo{:}, ['lmom' num2str(ii)]};
                end
                block_summary = { block_summary{:}, timeInfo, summaryInfo };
            end
            
            % return both blocks
            rval = { block_hist, block_summary };  
        end
        
    end
    
end
