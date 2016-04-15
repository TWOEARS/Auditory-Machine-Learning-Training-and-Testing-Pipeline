classdef SceneEarSignalProc < DataProcs.IdProcWrapper
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        sceneConfig;
        binauralSim;        % binaural simulator
        earSout;
        onOffsOut;
        annotsOut;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = SceneEarSignalProc( binauralSim )
            obj = obj@DataProcs.IdProcWrapper( binauralSim, false );
            obj.binauralSim = obj.wrappedProcs{1};
            obj.sceneConfig = SceneConfig.SceneConfiguration.empty;
        end
        %% ----------------------------------------------------------------

        function setSceneConfig( obj, sceneConfig )
            obj.sceneConfig = sceneConfig;
        end
        %% ----------------------------------------------------------------

        function fs = getDataFs( obj )
            fs = obj.binauralSim.getDataFs();
        end
        %% ----------------------------------------------------------------

        function process( obj, wavFilepath )
            obj.onOffsOut = [];
            obj.annotsOut = [];
            targetSignalLen = 1;
            splitEarSignals = cell( numel( obj.SceneConfig.sources ), 1 );
            srcClass = cell( numel( obj.SceneConfig.sources ), 1 );
            for ii = 1 : numel( obj.SceneConfig.sources )
                sc = obj.SceneConfig.getSingleConfig(ii);
                iiSignalLen = 0;
                while iiSignalLen < targetSignalLen - 0.01
                    scInst = sc.instantiate();
                    if ii == 1
                        scInst.sources(1).data = SceneConfig.FileListValGen( wavFilepath );
                        srcClass{ii} = IdEvalFrame.readEventClass( wavFilepath );
                    elseif isa( scInst.sources(1).data, 'SceneConfig.FileListValGen' )
                        wavFilepath = scInst.sources(1).data.value;
                        if isempty( wavFilepath )
                            error( 'Empty wav file name through use of FileListValGen!' );
                        end
                        srcClassii = IdEvalFrame.readEventClass( wavFilepath );
                        if ~isempty( srcClass{ii} ) && ~strcmp( srcClassii, srcClass{ii} )
                            error('Different classes used in looped distractor');
                        end
                        srcClass{ii} = srcClassii;
                    else
                        wavFilepath = ''; % don't save
                        srcClass{ii} = '';
                    end
                    obj.binauralSim.setSceneConfig( scInst );
                    splitOut = obj.binauralSim.processSaveAndGetOutput( wavFilepath );
                    if ~isempty( splitEarSignals{ii} )
                        splitOut.earSout = DataProcs.SceneEarSignalProc.adjustSNR( ...
                            obj.getDataFs(), splitEarSignals{ii}, 'energy', splitOut.earSout, 0 );
                    end
                    splitEarSignals{ii} = [splitEarSignals{ii}; splitOut.earSout];
                    targetSignalLen = length( splitEarSignals{1} ) / obj.getDataFs();
                    if ii > 1 && obj.SceneConfig.loop(ii)
                        iiSignalLen = length( splitEarSignals{ii} ) / obj.getDataFs();
                    else
                        iiSignalLen = targetSignalLen;
                    end
                    if strcmpi( srcClass{ii}, srcClass{1} )
                        maxLen = length( splitEarSignals{1} ) / obj.getDataFs();
                        splitOnOffs = splitOut.onOffsOut;
                        if isempty( splitOnOffs ), splitOnOffs = zeros(0,2); end
                        splitOnOffs( splitOnOffs(:,1) >= maxLen, : ) = [];
                        splitOnOffs( splitOnOffs > maxLen ) = maxLen;
                        obj.onOffsOut = sortAndMergeOnOffs( [obj.onOffsOut; splitOnOffs] );
                    end
                end
                fprintf( ':' );
            end
            fprintf( '::' );
            obj.earSout = splitEarSignals{1};
            for ii = 1 : 2
                [energy, tFramesSec] = DataProcs.SceneEarSignalProc.runningEnergy( ...
                                                             obj.getDataFs(), ...
                                                             double(obj.earSout(:,ii)), ...
                                                             100e-3, 50e-3 );
                obj.annotsOut.srcEnergy(1,ii,:) = single(energy);
            end
            obj.annotsOut.srcEnergy_t = single(tFramesSec);
            nTargetEnergyFrames = size( obj.annotsOut.srcEnergy, 3 );
            targetSignal = splitEarSignals{1}; % as in "S" in "SNR"
            for ii = 2:length( splitEarSignals )
                ovrlSignal = splitEarSignals{ii}; % as in "N" in "SNR"
                onOffs_samples = obj.onOffsOut .* obj.getDataFs();
                if isempty( onOffs_samples ), onOffs_samples = 'energy'; end;
                ovrlSignal = DataProcs.SceneEarSignalProc.adjustSNR( ...
                                                            obj.getDataFs(), ...
                                                            targetSignal, ...
                                                            onOffs_samples, ...
                                                            ovrlSignal, ...
                                                            obj.SceneConfig.SNRs(ii).value );
                maxSignalsLen = min( length( obj.earSout ), length( ovrlSignal ) );
                obj.earSout(1:maxSignalsLen,:) = ...
                    obj.earSout(1:maxSignalsLen,:) + ovrlSignal(1:maxSignalsLen,:);
                for jj = 1 : 2
                    energy = DataProcs.SceneEarSignalProc.runningEnergy( ...
                                                            obj.getDataFs(), ...
                                                            double(ovrlSignal(:,jj)), ...
                                                            100e-3, 50e-3 );
                    obj.annotsOut.srcEnergy(ii,jj,:) = ...
                                                  single( energy(1:nTargetEnergyFrames) );
                end
                fprintf( '.' );
            end
        end
        
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.sceneCfg = obj.sceneConfig;
            % SceneEarSignalProc doesn't (/must not) depend on the binSim's sceneConfig
            obj.binauralSim.setSceneConfig( SceneConfig.SceneConfiguration.empty );
            outputDeps.wrapDeps = getInternOutputDependencies@DataProcs.IdProcWrapper( obj );
        end
        %% ----------------------------------------------------------------

        function out = getOutput( obj )
            out.earSout = obj.earSout;
            out.onOffsOut = obj.onOffsOut;
            out.annotations = obj.annotsOut;
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Static)
        function signal2 = adjustSNR( fs, signal1, sig1OnOffs, signal2, snrdB )
            %adjustSNR   Adjust SNR between two signals. Only parts of the
            %signal that actually exhibit energy are factored into the SNR
            %computation.
            %   This function is based on adjustSNR by Tobias May.

            signal1(:,1) = signal1(:,1) - mean( signal1(:,1) );
            if size( signal1, 2 ) == 1
                signal1(:,2) = signal1(:,1);
            else
                signal1(:,2) = signal1(:,2) - mean( signal1(:,2) );
            end
            if isa( sig1OnOffs, 'char' ) && strcmpi( sig1OnOffs, 'energy' )
                s1actL = DataProcs.SceneEarSignalProc.detectActivity( fs, double(signal1(:,1)), 40, 50e-3, 50e-3, 10e-3 );
                s1actR = DataProcs.SceneEarSignalProc.detectActivity( fs, double(signal1(:,2)), 40, 50e-3, 50e-3, 10e-3 );
                signal1 = signal1(s1actL | s1actR,:);
            else
                sig1OnOffs(sig1OnOffs>length(signal1)) = length(signal1);
                signal1activePieces = arrayfun( ...
                    @(on, off)(signal1(ceil(on):floor(off),:)) , sig1OnOffs(:,1), sig1OnOffs(:,2), ...
                    'UniformOutput', false );
                signal1 = vertcat( signal1activePieces{:} );
            end
            signal2(:,1) = signal2(:,1) - mean( signal2(:,1) );
            s2actL = DataProcs.SceneEarSignalProc.detectActivity( fs, double(signal2(:,1)), 40, 50e-3, 50e-3, 10e-3 );
            if size( signal2, 2 ) > 1
                signal2(:,2) = signal2(:,2) - mean( signal2(:,2) );
                s2actR = DataProcs.SceneEarSignalProc.detectActivity( fs, double(signal2(:,2)), 40, 50e-3, 50e-3, 10e-3 );
            else
                s2actR = zeros( size( s2actL ) );
                signal2(:,2) = signal2(:,1);
            end
            signal2act = signal2(s2actL | s2actR,:);
            
            if isfinite(snrdB)
                % Multi-channel energy of speech and noise signals
                e_sig1 = sum(sum(signal1.^2));
                e_sig2  = sum(sum(signal2act.^2));
                e_sig1 = e_sig1 / length(signal1);
                e_sig2 = e_sig2 / length(signal2act);
                
                % Compute scaling factor for noise signal
                gain = sqrt((e_sig1/(10^(snrdB/10)))/e_sig2);
                
                % Adjust the noise level to get required SNR
                signal2 = gain * signal2;
            elseif isequal(snrdB,inf)
                % Set the noise signal to zero
                signal2 = signal2 * 0;
            else
                error('Invalid value of snrdB.')
            end
        end
        %% ----------------------------------------------------------------
        
        function [energy, tFramesSec] = runningEnergy( fs, signal, blockSec, stepSec )
            blockSize = 2 * round(fs * blockSec / 2);
            stepSize  = round(fs * stepSec);
            frames = frameData(signal,blockSize,stepSize,'rectwin');
            energy = 10 * log10(squeeze(mean(power(frames,2),1) + eps));
            cp = 0.98; % cumulative probability for quantile computation
            energySorted = sort(energy');
            nEnergy = numel(energy);
            q = interp1q([0 (0.5:(nEnergy-0.5))./nEnergy 1]',...
                         energySorted([1 1:nEnergy nEnergy],:),cp);
            energy = energy - q;
            tFramesSec = (stepSize:stepSize:stepSize*numel(energy)).'/fs;
        end
        %% ----------------------------------------------------------------
        
        function vad = detectActivity( fs, signal, thresdB, hSec, blockSec, stepSec )
            %detectActivity   Energy-based voice activity detection.
            %   This function is based on detectVoiceActivityKinnunen by
            %   Tobias May.
            %INPUT ARGUMENTS
            %           in : input signal [nSamples x 1]
            %      thresdB : energy threshold in dB, defining the dynamic range that is
            %                considered as speech activity (default, thresdB = 40)
            %       format : output format of VAD decision ('samples' or 'frames')
            %                (default, format = 'frames')
            %         hSec : hangover scheme in seconds (default, hSec = 50e-3)
            %     blockSec : blocksize in seconds (default, blockSec = 20e-3)
            %      stepSec : stepsize in seconds  (default, stepSec = 10e-3)
            %
            %OUTPUT ARGUMENTS
            %          vad : voice activity decision [nSamples|nFrames x 1]
            
            noiseFloor = -55;    % Noise floor
            
            % ************************  DETECT VOICE ACTIVITY  ***********************
            [energy, tFramesSec] = DataProcs.SceneEarSignalProc.runningEnergy( fs, signal, blockSec, stepSec );
            frameVAD = energy > -abs(thresdB) & energy > noiseFloor;
            % ***************************  HANGOVER SCHEME  **************************
            % Determine length of hangover scheme
            hangover = max(0,1+floor((hSec - blockSec)/stepSec));
            
            % Check if hangover scheme is active
            if hangover > 0
                % Initialize counter
                hangCtr = 0;
                
                % Loop over number of frames
                for ii = 1 : numel(energy)
                    % VAD decision
                    if frameVAD(ii) == true
                        % Speech detected, activate hangover scheme
                        hangCtr = hangover;
                    else
                        % Speech pause detected
                        if hangCtr > 0
                            % Delay detection of speech pause
                            frameVAD(ii) = true;
                            % Decrease hangover counter
                            hangCtr = hangCtr - 1;
                        end
                    end
                end
            end
            
            % *************************  RETURN VAD DECISION  ************************
            % Time vector in seconds
            tSec = (1:length(signal)).'/fs;
            
            % Convert frame-based VAD decision to samples
            vad = interp1(tFramesSec,double(frameVAD),tSec,'nearest','extrap');
            
            % Return logical VAD decision
            vad = logical(vad).';
        end
    end
    
end
