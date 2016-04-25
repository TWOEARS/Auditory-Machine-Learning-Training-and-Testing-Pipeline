classdef StandaloneMultiConfSceneSignalProc < simulator.RobotInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess=private)
        data;
        binauralSim;
        sceneConfBinauralSim;
        multiConfBinauralSim;
        targetSourceFiles;
        targetWav;
        targetsDir; % directory below which targetWav is stored
        targetLabels;
        targetOnOffs;
        earSout;
        currentEarSoutPos;
        SampleRate = 44100;
        BlockSize = 4096;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        function obj = StandaloneMultiConfSceneSignalProc( )
            obj.binauralSim = dataProcs.IdSimConvRoomWrapper( 'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa' );
            obj.sceneConfBinauralSim = dataProcs.SceneEarSignalProc( obj.binauralSim );
            obj.multiConfBinauralSim = dataProcs.MultiSceneCfgsIdProcWrapper( obj.binauralSim, obj.sceneConfBinauralSim );
            obj.currentEarSoutPos = 1;
        end
        %% ----------------------------------------------------------------
        
        function setupData( obj, flist )
            obj.data = core.IdentTrainPipeData();
            obj.data.loadWavFileList( flist );
        end
        %% ----------------------------------------------------------------
        
        function makeRandomTargetSourceSequence( obj, targetSrcFlist, len, targetClasses, targetShare )
            targetWavs = dir( [pwd filesep 'targets' filesep '*_target.wav'] );
            if numel( targetWavs ) > 0 
                for ii = 1 : numel( targetWavs )
                    fprintf( '%d) %s \n', ii, targetWavs(ii).name );
                end
                choice = input( ['\nUse any of the above found target wavs? Select with number, ' ...
                    'or plain Enter to create new. >> '], 's' );
                if ~isempty( choice )
                    choice = str2num( choice );
                    tw = load( ['targets' filesep targetWavs(choice).name '.mat'] );
                    obj.targetLabels = tw.labels;
                    obj.targetOnOffs = tw.targetOnOffs;
                    obj.targetWav = tw.targetWav;
                    clear tw;
                end
            end
            if isempty( obj.targetWav )
                if ~isempty( targetSrcFlist )
                    wavs = readFileList( targetSrcFlist );
                else
                    wavs = obj.data(:,:,'wavFileName');
                end
                classes = cellfun( @IdEvalFrame.readEventClass, wavs, 'UniformOutput', false);
                targetWavs = {};
                otherWavs = {};
                for ii = 1 : numel( wavs )
                    if any( strcmp( classes{ii}, targetClasses ) )
                        targetWavs = [targetWavs; wavs(ii)];
                    else
                        otherWavs = [otherWavs; wavs(ii)];
                    end
                end
                targetWavs = targetWavs(randperm(numel(targetWavs)));
                otherWavs = otherWavs(randperm(numel(otherWavs)));
                targetMinLen = len * targetShare;
                ii = 0;
                tlen = 0;
                while tlen < targetMinLen
                    ii = ii + 1;
                    [a,fs] = audioread( targetWavs{ii} );
                    tlen = tlen + length( a ) / fs;
                    clear a;
                end
                targetWavs(ii+1:end) = [];
                ii = 0;
                olen = 0;
                while olen < (len - targetMinLen)
                    ii = ii + 1;
                    [a,fs] = audioread( otherWavs{ii} );
                    olen = olen + length( a ) / fs;
                    clear a;
                end
                otherWavs(ii+1:end) = [];
                wavs = [targetWavs; otherWavs];
                wavs = wavs(randperm(numel(wavs)));
                [sourceSignals, sourceLabels] = readAudioFiles(...
                    wavs, ...
                    'Samplingrate', obj.SampleRate, ...
                    'Zeropadding', 0.25 * obj.SampleRate,...
                    'Normalize', true, ...
                    'CellOutput', true);
                sourceSignal = sourceSignals{1};
                sourceSignal(:,1) = sourceSignal(:,1) - mean( sourceSignal(:,1) );
                if size( sourceSignal, 2 ) == 1
                    sourceSignal(:,2) = sourceSignal(:,1);
                else
                    sourceSignal(:,2) = sourceSignal(:,2) - mean( sourceSignal(:,2) );
                end
                for ii = 2 : numel( sourceSignals )
                    sourceSignals{ii} = dataProcs.SceneEarSignalProc.adjustSNR( obj.SampleRate, ...
                        sourceSignal, 'energy', sourceSignals{ii}, 0 );
                    sourceSignal = [sourceSignal; sourceSignals{ii}];
                    fprintf( '.' );
                end
                sourceSignal = sourceSignal / max( abs( sourceSignal(:) ) ); % normalize
                obj.targetOnOffs = vertcat(sourceLabels.cumOnsetsOffsets);
                labels = {};
                for ii = 1 : numel( sourceLabels )
                    if isempty( sourceLabels(ii).class )
                        continue;
                    elseif size( sourceLabels(ii).class, 1 ) == 1
                        labels = [labels {sourceLabels(ii).class}];
                    else
                        for jj = 1 : size( sourceLabels(ii).class, 1 )
                            labels = [labels {sourceLabels(ii).class(jj,:)}];
                        end
                    end
                end
                obj.targetLabels = labels;
                audiohash = calcDataHash( wavs );
                obj.targetWav = fullfile(obj.targetsDir, [audiohash '_target.wav']);
                audiowrite( obj.targetWav, sourceSignal, obj.SampleRate );
                targetWav = obj.targetWav;
                targetOnOffs = obj.targetOnOffs;
                save( [targetWav '.mat'], 'labels', 'targetOnOffs', 'targetWav' );
            end
        end
        %% ----------------------------------------------------------------
        
        function labels = getLabels( obj )
            labels = obj.targetLabels;
        end
        %% ----------------------------------------------------------------

        function preprocessScene( obj )
            obj.multiConfBinauralSim.processSaveAndGetOutput( obj.targetWav );
            targetSceneProcFile = obj.multiConfBinauralSim.getOutputObject().getOutputFilepath( obj.targetWav );
            eo = load( targetSceneProcFile, 'earSout' );
            obj.earSout = eo.earSout;
            obj.currentEarSoutPos = 1;
        end
        %% ----------------------------------------------------------------
        
        function onOffsets = getOnOffsets( obj )
            onOffsets = obj.targetOnOffs;
        end
        %% ----------------------------------------------------------------
        
        function setSceneConfig( obj, sc )
            obj.sceneConfBinauralSim.setSceneConfig( sc );
            obj.multiConfBinauralSim.setSceneConfig( sc );
        end
        
        function setCacheSystemDir( obj, cacheSystemDir, nPathLevelsForCacheName )
            obj.multiConfBinauralSim.setCacheSystemDir( cacheSystemDir, nPathLevelsForCacheName );
        end
        
        function setTargetsDir( obj, targetsDir )
            if exist(targetsDir, 'dir')
                obj.targetsDir = targetsDir;
            else
                error( 'Targets directory does not exist. Please create it. (%s)', targetsDir);
            end
        end
        %% ----------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    % Robot-Interface
    methods (Access=protected)
        function rotateHeadRelative(obj, angleIncDeg)
            error( 'not implemented in StandaloneMultiConfSceneSignalProc' );
        end
        %% ----------------------------------------------------------------
        function rotateHeadAbsolute(obj, angleDeg)
            error( 'not implemented in StandaloneMultiConfSceneSignalProc' );
        end
        %% ----------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        function azimuth = getCurrentHeadOrientation(obj)
            azimuth = 0;
            warning( 'TODO' );
        end
        %% ----------------------------------------------------------------
        
        function [sig, timeIncSec, timeIncSamples] = getSignal(obj, timeIncSec)
            timeIncSamples = timeIncSec * obj.SampleRate;
            maxEarSoutSamples = min( length( obj.earSout ), obj.currentEarSoutPos + timeIncSamples - 1 );
            sig = obj.earSout(obj.currentEarSoutPos:maxEarSoutSamples,:);
            obj.currentEarSoutPos = obj.currentEarSoutPos + timeIncSamples;
        end
        %% ----------------------------------------------------------------

        function b = isFinished( obj )
            b = obj.currentEarSoutPos >= length( obj.earSout );
        end
        %% ----------------------------------------------------------------
    end
    
end
