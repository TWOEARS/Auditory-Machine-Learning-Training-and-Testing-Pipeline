classdef IdSimConvRoomWrapper < IdWp1ProcInterface
    
    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        convRoomSim;
        multiConditions;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)

    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdSimConvRoomWrapper( simConvRoomXML )
            obj = obj@IdWp1ProcInterface();
            obj.multiConditions = MultiCondition.empty;
            obj.convRoomSim = simulator.SimulatorConvexRoom( simConvRoomXML, false );
%            obj.convRoomSim = simulator.SimulatorConvexRoom();
%            set(obj.convRoomSim, ...
%                'BlockSize', 4096, ...
%                'SampleRate', 44100, ...
%		'MaximumDelay', 0.05, ...
%		'PreDelay', 0.0, ...
%		'Renderer', @ssr_binaural, ...
%                'HRIRDataset', simulator.DirectionalIR( xml.dbGetFile( ...
%                'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa')) ...
%                );
%            set(obj.convRoomSim, ...
%                'Sinks', simulator.AudioSink(2) ...
%                );
%            set(obj.convRoomSim.Sinks, ...
%                'Position' , [0; 0; 1.75], ...
%                'UnitFront', [1; 0; 0], ...
%                'UnitUp', [0; 0; 1], ...
%                'Name', 'Head' ...
%                );
        end
        
        function delete( obj )
            obj.convRoomSim.set('ShutDown',true);
        end
        
        function hashMembers = getHashObjects( obj )
            hashMembers = {obj.multiConditions, ...
                obj.convRoomSim.SampleRate, ...
                obj.convRoomSim.MaximumDelay, ...
                obj.convRoomSim.PreDelay, ...
                obj.convRoomSim.ReverberationRoomType, ...
                obj.convRoomSim.ReverberationMaxOrder, ...
                obj.convRoomSim.Renderer, ...
                audioread( obj.convRoomSim.HRIRDataset.Filename )};
        end

        %%-----------------------------------------------------------------
        
        function addMultiCondition( obj, mc )
            obj.multiConditions(end+1) = mc;
        end
        
        %%-----------------------------------------------------------------

        function fs = getDataFs( obj )
            fs = obj.convRoomSim.SampleRate;
        end
        
        %%-----------------------------------------------------------------
        
        function [earSignals, earsOnOffs] = makeEarsignalsAndLabels( obj, wavFile )
            earSignals = zeros( 0, 2 );
            earsOnOffs = zeros( 0, 2 );
            for mc = obj.multiConditions
                [mcEarSignals, mcOnOffs] = obj.makeEarSignalsForOneMC( wavFile, mc );
                earsOnOffs = [earsOnOffs; (length(earSignals) / obj.convRoomSim.SampleRate) + mcOnOffs];
                earSignals = [earSignals; mcEarSignals];
            end
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
        
        function [earSignals, onOffs] = makeEarSignalsForOneMC( obj, wavFile, mc )
            mcInst = mc.instantiate();
            [sounds, onOffs] = obj.loadSounds( mcInst, wavFile );
            obj.setupProcForMc( mcInst );
            for kk = 1:length( sounds )
                if kk > 1  && strcmpi( mcInst.typeOverlays{kk-1}, 'diffuse' )
                    es{kk} = sounds{kk}(1:min( length( sounds{kk} ), length( es{1} ) ),:);
                else
                    obj.setNewSourceData( sounds );
                    obj.setSourceOnlyActive( kk );
                    obj.wp1Process();
                    es{kk} = obj.convRoomSim.Sinks.getData();
                end
                fprintf( '\n' );
            end
            sSignal = es{1};
            earSignals = sSignal;
            for kk = 2:length( es )
                sOnOffsSamples = onOffs .* obj.convRoomSim.SampleRate;
                nSignal = es{kk};
                nSignal = obj.adjustSNR( ...
                    sSignal, sOnOffsSamples, nSignal, mcInst.SNRs(kk-1).value );
                earSignals(1:min( length( earSignals ), length( nSignal ) ),:) = ...
                    earSignals(1:min( length( earSignals ), length( nSignal ) ),:) ...
                    + nSignal;
            end
            earSignals = earSignals / max( abs( earSignals(:) ) ); % normalize
        end

        %%
        function setNewSourceData( obj, sounds )
            sigLen_s = length( sounds{1} ) / obj.convRoomSim.SampleRate;
            obj.convRoomSim.set( 'LengthOfSimulation', sigLen_s );
            obj.convRoomSim.Sinks.removeData();
            for m = 1:length(obj.convRoomSim.Sources)
                obj.convRoomSim.Sources{m}.setData( sounds{m} );
            end
        end
        
        %%
        function setSourceOnlyActive( obj, actIdx )
            for m = 1:length(obj.convRoomSim.Sources)
                obj.convRoomSim.Sources{m}.set( 'Volume', 0.0 );
                obj.convRoomSim.Sources{m}.set( 'Mute', 1 );
            end
            obj.convRoomSim.Sources{actIdx}.set( 'Mute', 0 );
            obj.convRoomSim.Sources{actIdx}.set( 'Volume', 1.0 );
        end
        
        %%
        function wp1Process( obj )
            obj.convRoomSim.set( 'ReInit', true );
            while ~obj.convRoomSim.isFinished()
                obj.convRoomSim.set('Refresh',true);  % refresh all objects
                obj.convRoomSim.set('Process',true);  % processing
                fprintf( '.' );
            end
        end
        
        %%
        function setupProcForMc( obj, mc )
            obj.convRoomSim.set( 'ShutDown', true );
            if length(obj.convRoomSim.Sources) > 1, obj.convRoomSim.Sources(2:end) = []; end;
            useReverb = ~isempty( mc.walls.value );
            if useReverb, obj.convRoomSim.Walls = mc.walls.value; end
            obj.createNewSimSource( 1, useReverb, true, mc.distSignal.value, mc.angleSignal.value );
            for kk = 1:mc.numOverlays
                isPoint = strcmpi( mc.typeOverlays{kk}, 'point' );
                obj.createNewSimSource( ...
                    kk+1, useReverb, isPoint, mc.distOverlays(kk).value, mc.angleOverlays(kk).value...
                    );
            end
            obj.convRoomSim.set('Init',true);
        end

        %%
        function createNewSimSource( obj, idx, useReverb, isPoint, radius, azmth )
            if isPoint 
                if useReverb
                    obj.convRoomSim.Sources{idx} = simulator.source.ISMShoeBox( obj.convRoomSim );
                else
                    obj.convRoomSim.Sources{idx} = simulator.source.Point();
                end
                channelMapping = [1];
            else % ~isPoint
                obj.convRoomSim.Sources{idx} = simulator.source.Binaural();
                channelMapping = [1 2];
            end
            obj.convRoomSim.Sources{idx}.set( 'Radius', radius );
            obj.convRoomSim.Sources{idx}.set( 'Azimuth', azmth );
            obj.convRoomSim.Sources{idx}.AudioBuffer = simulator.buffer.FIFO( channelMapping );
        end
        
        %%
        function [sounds, sigOnOffs] = loadSounds( obj, mc, wavFile )
            zeroOffsetLength_s = 0.25;
            sounds{1} = getPointSourceSignalFromWav( ...
                wavFile, obj.convRoomSim.SampleRate, zeroOffsetLength_s );
            sigOnOffs = ...
                IdEvalFrame.readOnOffAnnotations( wavFile ) + zeroOffsetLength_s;
            sigClass = IdEvalFrame.readEventClass( wavFile );
            for kk = 1:mc.numOverlays
                ovrlFile = mc.fileOverlays(kk).value;
                ovrlZeroOffset = mc.offsetOverlays(kk).value;
                if strcmpi( mc.typeOverlays{kk}, 'point' )
                    sounds{1+kk} = ...
                        getPointSourceSignalFromWav( ...
                            ovrlFile, obj.convRoomSim.SampleRate, ...
                            ovrlZeroOffset );
                elseif strcmpi( mc.typeOverlays{kk}, 'diffuse' )
                    diffuseMonoSound = ...
                        getPointSourceSignalFromWav( ...
                            ovrlFile, obj.convRoomSim.SampleRate, ...
                            ovrlZeroOffset );
                    sounds{1+kk} = repmat( diffuseMonoSound, 1, 2 );
                end
                ovrlClass = IdEvalFrame.readEventClass( ovrlFile );
                if strcmpi( ovrlClass, sigClass )
                    maxLen = length( sounds{1} ) / obj.convRoomSim.SampleRate;
                    ovrlOnOffs = IdEvalFrame.readOnOffAnnotations( ovrlFile ) ...
                        + ovrlZeroOffset;
                    ovrlOnOffs( ovrlOnOffs(:,1) >= maxLen, : ) = [];
                    ovrlOnOffs( ovrlOnOffs > maxLen ) = maxLen;
                    sigOnOffs = sortAndMergeOnOffs( [sigOnOffs; ovrlOnOffs] );
                end
            end
        end
        
        %%
        function signal2 = adjustSNR( obj, signal1, sig1OnOffs, signal2, snrdB )
            %adjustSNR   Adjust SNR between two signals. Only parts of the
            %signal that actually exhibit energy are factored into the SNR
            %computation.
            %   This function is based on adjustSNR by Tobias May.

            signal1(:,1) = signal1(:,1) - mean( signal1(:,1) );
            signal1(:,2) = signal1(:,2) - mean( signal1(:,2) );
            sig1OnOffs(sig1OnOffs>length(signal1)) = length(signal1);
            signal1activePieces = arrayfun( ...
                @(on, off)(signal1(ceil(on):floor(off),:)) , sig1OnOffs(:,1), sig1OnOffs(:,2), ...
                'UniformOutput', false );
            signal1 = vertcat( signal1activePieces{:} );
            signal2activity(:,1) = signal2(:,1) - mean( signal2(:,1) );
            signal2activity(:,2) = signal2(:,2) - mean( signal2(:,2) );
            s2actL = obj.detectActivity( double(signal2activity(:,1)), 40, 50e-3, 50e-3, 10e-3 );
            s2actR = obj.detectActivity( double(signal2activity(:,2)), 40, 50e-3, 50e-3, 10e-3 );
            signal2activity = signal2activity(s2actL | s2actR,:);
            
            if isfinite(snrdB)
                % Multi-channel energy of speech and noise signals
                e_sig1 = sum(sum(signal1.^2));
                e_sig2  = sum(sum(signal2activity.^2));
                e_sig1 = e_sig1 / length(signal1);
                e_sig2 = e_sig2 / length(signal2activity);
                
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
        
        function vad = detectActivity( obj, signal, thresdB, hSec, blockSec, stepSec )
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
            
            % **************************  FRAME-BASED ENERGY  ************************
            blockSize = 2 * round(obj.convRoomSim.SampleRate * blockSec / 2);
            stepSize  = round(obj.convRoomSim.SampleRate * stepSec);
            
            frames = frameData(signal,blockSize,stepSize,'rectwin');
            
            energy = 10 * log10(squeeze(mean(power(frames,2),1) + eps));
            
            nFrames = numel(energy);
            
            % ************************  DETECT VOICE ACTIVITY  ***********************
            % Set maximum to 0 dB
            energy = energy - max(energy);
            
            frameVAD = energy > -abs(thresdB) & energy > noiseFloor;
            
            % Corresponding time vector in seconds
            tFramesSec = (stepSize:stepSize:stepSize*nFrames).'/obj.convRoomSim.SampleRate;
            
            % ***************************  HANGOVER SCHEME  **************************
            % Determine length of hangover scheme
            hangover = max(0,1+floor((hSec - blockSec)/stepSec));
            
            % Check if hangover scheme is active
            if hangover > 0
                % Initialize counter
                hangCtr = 0;
                
                % Loop over number of frames
                for ii = 1 : nFrames
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
            tSec = (1:length(signal)).'/obj.convRoomSim.SampleRate;
            
            % Convert frame-based VAD decision to samples
            vad = interp1(tFramesSec,double(frameVAD),tSec,'nearest','extrap');
            
            % Return logical VAD decision
            vad = logical(vad).';
        end
        
    end
    
    
end
