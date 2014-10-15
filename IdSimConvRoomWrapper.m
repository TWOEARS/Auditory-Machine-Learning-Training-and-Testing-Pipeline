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
            obj.addMultiCondition( MultiCondition() ); % clean condition
        end
        
        function delete( obj )
            obj.convRoomSim.set('ShutDown',true);
        end
        
        %%-----------------------------------------------------------------
        
        function addMultiCondition( obj, mc )
            obj.multiConditions(end+1) = mc;
        end
        
        %%-----------------------------------------------------------------
        
        function [earSignals, earsOnOffs] = makeEarsignalsAndLabels( obj, trainFile )
            zeroOffsetLength_s = 0.25;
            monoSound = getPointSourceSignalFromWav( ...
                trainFile.wavFileName, obj.convRoomSim.SampleRate, zeroOffsetLength_s );
            monoOnOffs = ...
                IdEvalFrame.readOnOffAnnotations( trainFile.wavFileName ) + zeroOffsetLength_s;
            earSignals = zeros( 0, 2 );
            earsOnOffs = zeros( 0, 2 );
            for mc = obj.multiConditions
                earsOnOffs = [earsOnOffs; (length(earSignals) / obj.convRoomSim.SampleRate) + monoOnOffs];
                earSignals = [earSignals; obj.makeEarSignals( monoSound, mc, monoOnOffs )];
            end
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function earSignals = makeEarSignals( obj, monoSound, mcond, monoOnOffs )
            sounds{1} = monoSound;
            sounds = [sounds, mcond.setupWp1Proc( obj.convRoomSim )];
            for k = 1:1+mcond.numOverlays
                obj.convRoomSim.set( 'LengthOfSimulation', length(monoSound) / obj.convRoomSim.SampleRate );
                obj.convRoomSim.Sinks.removeData();
                for m = 1:length(obj.convRoomSim.Sources)
                    obj.convRoomSim.Sources{m}.setData( sounds{m} );
                    obj.convRoomSim.Sources{m}.set( 'Volume', 0.0 );
                    obj.convRoomSim.Sources{m}.set( 'Mute', 1 );
                end
                obj.convRoomSim.Sources{k}.set( 'Mute', 0 );
                obj.convRoomSim.Sources{k}.set( 'Volume', 1.0 );
                obj.convRoomSim.set( 'ReInit', true );
                while ~obj.convRoomSim.Sources{1}.isEmpty()
                    obj.convRoomSim.set('Refresh',true);  % refresh all objects
                    obj.convRoomSim.set('Process',true);  % processing
                    fprintf( '.' );
                end
                es{k} = obj.convRoomSim.Sinks.getData();
                es{k} = es{k} / max( abs( es{k}(:) ) ); % normalize
                fprintf( '\n' );
            end
            sSignal = es{1};
            earSignals = sSignal;
            for k = 2:length( es )
                sOnOffsSamples = monoOnOffs .* obj.convRoomSim.SampleRate;
                nSignal = es{k};
                nSignal = obj.adjustSNR( ...
                    sSignal, sOnOffsSamples, nSignal, mcond.SNRs(k-1).genVal() );
                earSignals = earSignals + nSignal;
            end
        end
        
        function signal2 = adjustSNR( obj, signal1, sig1OnOffs, signal2, snrdB )
            %adjustSNR   Adjust SNR between two signals. Only parts of the
            %signal that actually exhibit energy are factored into the SNR
            %computation.
            %   This function is based on adjustSNR by Tobias May.

            signal1(:,1) = signal1(:,1) - mean( signal1(:,1) );
            signal1(:,2) = signal1(:,2) - mean( signal1(:,2) );
            signal1activePieces = arrayfun( ...
                @(on, off)(signal1(on:off,:)) , sig1OnOffs(:,1), sig1OnOffs(:,2), ...
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

% function wp2processSounds( dfiles, esetup )
%
% disp( 'wp2 processing of sounds' );
%
% wp2DataHash = getWp2dataHash( esetup );
%
% for k = 1:length( dfiles.soundFileNames )
%
%     wp2SaveName = [dfiles.soundFileNames{k} '.' wp2DataHash '.wp2.mat'];
%     if exist( wp2SaveName, 'file' )
%         fprintf( '.' );
%         continue;
%     end;
%
%     fprintf( '\n%s', wp2SaveName );
%
%     wp2data = [];
%     for angle = esetup.wp2dataCreation.angle
%
%         fprintf( '.' );
%
%         dObj = [];
%         mObj = [];
%         wp2procs = [];
%         dObj = dataObject( [], esetup.wp2dataCreation.fs, 2, 1 );
%         mObj = manager( dObj );
%         for z = 1:length( esetup.wp2dataCreation.requests )
%             wp2procs{z} = mObj.addProcessor( esetup.wp2dataCreation.requests{z}, esetup.wp2dataCreation.requestP{z} );
%         end
%         tmpData = cell( size(wp2procs,2), size(wp2procs{1},2) );
%         for pos = 1:esetup.wp2dataCreation.fs:length(earSignals)
%             posEnd = min( length( earSignals ), pos + esetup.wp2dataCreation.fs - 1 );
%             mObj.processChunk( earSignals(pos:posEnd,:), 0 );
%             for z = 1:size(wp2procs,2)
%                 for zz = 1:size(wp2procs{z},2)
%                     tmpData{z,zz} = [tmpData{z,zz}; wp2procs{z}{zz}.Data];
%                 end
%             end
%             fprintf( '.' );
%         end
%         for z = 1:size(wp2procs,2)
%             for zz = 1:size(wp2procs{z},2)
%                 wp2procs{z}{zz}.Data = tmpData{z,zz};
%             end
%         end
%         wp2data = [wp2data wp2procs(:)];
%     end
%
%     save( wp2SaveName, 'wp2data', 'esetup' );
%
% end
%
%
% disp( ';' );
