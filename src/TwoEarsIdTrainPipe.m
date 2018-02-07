classdef TwoEarsIdTrainPipe < handle
    % TwoEarsIdTrainPipe Two!Ears identification training pipeline wrapper
    %   This wraps around the Two!Ears identification training pipeline
    %   which facilitates training models for classifying sounds.
    %   It manages the data for training and testing, drives the binaural
    %   simulator, orchestrates feature extraction, optimizes the model and
    %   produces performance metrics for evaluating a model.
    %   Trained models can then be integrated into the blackboard system
    %   by loading them in an identitiy knowledge source
    %
    %   The train and test can be specified individually or the data is
    %   provided to be split by the pipeline
    %
    %% --------------------------------------------------------------------
    properties (SetAccess = public)
        binSim = [];
        blockCreator = [];      % (default: BlockCreators.MeanStandardBlockCreator( 1.0, 0.4 ))
        labelCreator = [];
        ksWrapper = [];
        featureCreator = [];    % feature extraction (default: featureCreators.RatemapPlusDeltasBlockmean())
        modelCreator = [];      % model trainer
        trainsetShare = 0.5;
        checkFileExistence = true;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        pipeline;
        dataSetupAlreadyDone = false;   % pre-processing steps already done.
        dataFlists = [];              % list of files to split in train and test
        trainFlists = [];          % file list with train examples
        testFlists = [];           % file list with test examples
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = TwoEarsIdTrainPipe( varargin )
            % TwoEarsIdTrainPipe Construct a training pipeline
            %   TwoEarsIdTrainPipe() instantiate using the default cache-
            %   system and sound-db base directories
            %
            ip = inputParser;
            ip.addOptional( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
            ip.addOptional( 'nPathLevelsForCacheName', 3 );
            ip.parse( varargin{:} );
            ModelTrainers.Base.featureMask( true, [] ); % reset the feature mask
            fprintf( '\nmodelTrainers.Base.featureMask set to []\n' );
            obj.pipeline = Core.IdentificationTrainingPipeline( ...
                                          'cacheSystemDir', ip.Results.cacheSystemDir, ...
                                          'nPathLevelsForCacheName', ip.Results.nPathLevelsForCacheName );
            obj.dataSetupAlreadyDone = false;
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj, sceneCfgs, varargin )
            % init initialize training pipeline
            %   init() init using the default impulse
            %   response dataset to drive the binaural simulator
            %   init( sceneCfgs, 'hrir', hrir ) instantiate using a path to the 
            %   impulse response dataset defined by hrir
            %   (e.g. 'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa'
            %   
            ip = inputParser;
            ip.addOptional( 'hrir', ...
                            'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa' );
            ip.addOptional( 'sceneCfgDataUseRatio', inf );
            ip.addOptional( 'sceneCfgPrioDataUseRatio', inf );
            ip.addOptional( 'selectPrioClass', [] );
            ip.addOptional( 'dataSelector', DataSelectors.IgnorantSelector() );
            ip.addOptional( 'loadBlockAnnotations', false );
            ip.addOptional( 'gatherFeaturesProc', true );
            ip.addOptional( 'trainerFeedDataType', @single );
            ip.addOptional( 'stopAfterProc', inf );
            ip.addOptional( 'fs', 44100 );
            ip.addOptional( 'wavFoldAssignments', {} );
            ip.addOptional( 'classesOnMultipleSourcesFilter', {} );
            ip.addOptional( 'pipeReUse', 0 );
            ip.addOptional( 'keepData', 'no' ); % 'no','y','x'
            ip.parse( varargin{:} );
            hrir = ip.Results.hrir;
            fs = ip.Results.fs;
            classesOnMultipleSourcesFilter = ip.Results.classesOnMultipleSourcesFilter;
            wavFoldAssignments = ip.Results.wavFoldAssignments;
            useGatherFeaturesProc = ip.Results.gatherFeaturesProc;
            trainerFeedDataType = ip.Results.trainerFeedDataType;
            loadBlockAnnotations = ip.Results.loadBlockAnnotations;
            sceneCfgDataUseRatio = ip.Results.sceneCfgDataUseRatio;
            sceneCfgPrioDataUseRatio = ip.Results.sceneCfgPrioDataUseRatio;
            selectPrioClass = ip.Results.selectPrioClass;
            dataSelector = ip.Results.dataSelector;
            stopAfterProc = ip.Results.stopAfterProc;
            pipeReUseIdx = ip.Results.pipeReUse;

            if isempty( obj.featureCreator )
                error( 'Please specify featureCreator.' );
            end
            if isempty( obj.labelCreator )
                error( 'Please specify labelCreator.' );
            end

            obj.setupData( true );
            switch ip.Results.keepData
                case 'no'
                    obj.pipeline.data.clear( 'all' );
                otherwise
                    error( 'Is this really senseful?' );
            end
            
            multiCfgProcs = {};
            if pipeReUseIdx < 1 || isempty( obj.binSim ) ...
                    || numel( obj.pipeline.dataPipeProcs ) < 1 ...
                    || isempty( obj.pipeline.dataPipeProcs{1} )
                obj.binSim = DataProcs.SceneEarSignalProc( ...
                                            DataProcs.IdSimConvRoomWrapper( hrir, fs ),...
                                                         classesOnMultipleSourcesFilter );
                multiCfgProcs{1} = DataProcs.MultiSceneCfgsIdProcWrapper( ...
                                         obj.binSim, obj.binSim, [], wavFoldAssignments );
                obj.pipeline.resetDataProcs( 1 );
            end
            ksWrapperIdxAdd = double( ~isempty( obj.ksWrapper ) );
            if pipeReUseIdx < 4+ksWrapperIdxAdd ...
                    || numel( obj.pipeline.dataPipeProcs ) < 4+ksWrapperIdxAdd ...
                    || isempty( obj.pipeline.dataPipeProcs{4+ksWrapperIdxAdd} )
                afeReqs = obj.featureCreator.getAFErequests();
                if ~isempty( obj.ksWrapper )
                    obj.ksWrapper.setAfeDataIndexOffset( numel( afeReqs ) );
                    afeReqs = [afeReqs obj.ksWrapper.getAfeRequests];
                end
                obj.pipeline.featureCreator = obj.featureCreator;
                multiCfgProcs{2} = DataProcs.MultiSceneCfgsIdProcWrapper( obj.binSim, ...
                   DataProcs.ParallelRequestsAFEmodule( obj.binSim.getDataFs(), afeReqs ), ...
                                                                 [], wavFoldAssignments );
                if isempty( obj.blockCreator )
                    obj.blockCreator = BlockCreators.MeanStandardBlockCreator( 0.5, 1.0/3 );
                end
                obj.pipeline.blockCreator = obj.blockCreator;
                multiCfgProcs{3} = DataProcs.MultiSceneCfgsIdProcWrapper( ...
                                   obj.binSim, obj.blockCreator, [], wavFoldAssignments );
                if ~isempty( obj.ksWrapper )
                    multiCfgProcs{4} = DataProcs.MultiSceneCfgsIdProcWrapper( ...
                                      obj.binSim, obj.ksWrapper, [], wavFoldAssignments );
                end
                multiCfgProcs{4+ksWrapperIdxAdd} = ...
                    DataProcs.MultiSceneCfgsIdProcWrapper( ...
                                 obj.binSim, obj.featureCreator, [], wavFoldAssignments );
                obj.pipeline.resetDataProcs( 2 );
            end
            if pipeReUseIdx < 5+ksWrapperIdxAdd ...
                    || numel( obj.pipeline.dataPipeProcs ) < 5+ksWrapperIdxAdd ...
                    || isempty( obj.pipeline.dataPipeProcs{5+ksWrapperIdxAdd} )
                multiCfgProcs{5+ksWrapperIdxAdd} = ...
                    DataProcs.MultiSceneCfgsIdProcWrapper( ...
                                   obj.binSim, obj.labelCreator, [], wavFoldAssignments );
                obj.pipeline.resetDataProcs( 5+ksWrapperIdxAdd );
            end
            if useGatherFeaturesProc && ...
                    ( numel( obj.pipeline.dataPipeProcs ) < 6+ksWrapperIdxAdd ...
                      || isempty( obj.pipeline.dataPipeProcs{6+ksWrapperIdxAdd} ) )
                gatherFeaturesProc = DataProcs.GatherFeaturesProc( ...
                                              loadBlockAnnotations, trainerFeedDataType );
                gatherFeaturesProc.setSceneCfgDataUseRatio( ...
                                              sceneCfgDataUseRatio, dataSelector, ...
                                              sceneCfgPrioDataUseRatio, selectPrioClass );
                multiCfgProcs{6+ksWrapperIdxAdd} = ...
                    DataProcs.MultiSceneCfgsIdProcWrapper( ...
                                 obj.binSim, gatherFeaturesProc, [], wavFoldAssignments );
            end
            for ii = 1 : min( numel( multiCfgProcs ), stopAfterProc )
                if isempty( multiCfgProcs{ii} )
                    if ~isempty( obj.pipeline.dataPipeProcs{ii} )
                        obj.pipeline.dataPipeProcs{ii}.dataFileProcessor.setSceneConfig( sceneCfgs );
                        obj.pipeline.dataPipeProcs{ii}.init();
                    end
                    continue; 
                end
                multiCfgProcs{ii}.setSceneConfig( sceneCfgs );
                obj.pipeline.addDataPipeProc( multiCfgProcs{ii} );
            end
            if isempty( obj.modelCreator )
                obj.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
                    'performanceMeasure', @performanceMeasures.BAC2, ...
                    'cvFolds', 4, ...
                    'alpha', 0.99 );
            end
            obj.pipeline.addModelCreator( obj.modelCreator );
        end
        %% -------------------------------------------------------------------------------

        function setTrainset( obj, newTrainFlists )
            obj.dataSetupAlreadyDone = all( strcmp(obj.trainFlists,newTrainFlists) );
            if ~iscell( newTrainFlists )
                newTrainFlists = {newTrainFlists};
            end
            obj.trainFlists = newTrainFlists;
        end
        %% -------------------------------------------------------------------------------

        function setTestset( obj, newTestFlists )
            obj.dataSetupAlreadyDone = all( strcmp(obj.testFlists,newTestFlists) );
            if ~iscell( newTestFlists )
                newTestFlists = {newTestFlists};
            end
            obj.testFlists = newTestFlists;
        end
        %% -------------------------------------------------------------------------------

        function setData( obj, newDataFlists )
            % set the data to be split into train and test set by the
            % pipeline
            obj.dataSetupAlreadyDone = all( strcmp(obj.dataFlists,newDataFlists) );
            if ~iscell( newDataFlists )
                newDataFlists = {newDataFlists};
            end
            obj.dataFlists = newDataFlists;
        end
        %% -------------------------------------------------------------------------------

        function setupData( obj, skipIfAlreadyDone )
            % setupData set up the train and test set and perform a
            % train/test split on the data if not already specified.
            if nargin > 1 && skipIfAlreadyDone && obj.dataSetupAlreadyDone
                return;
            end
            if ~isempty( obj.trainFlists ) || ~isempty( obj.testFlists )
                trainFolds = cell( 1, numel( obj.trainFlists ) );
                for ii = 1 : numel( obj.trainFlists )
                    trainFolds{ii} = Core.IdentTrainPipeData();
                    trainFolds{ii}.loadFileList( obj.trainFlists{ii}, obj.checkFileExistence );
                end
                obj.pipeline.setTrainData( Core.IdentTrainPipeData.combineData( trainFolds{:} ) );
                testFolds = cell( 1, numel( obj.testFlists ) );
                for ii = 1 : numel( obj.testFlists )
                    testFolds{ii} = Core.IdentTrainPipeData();
                    testFolds{ii}.loadFileList( obj.testFlists{ii}, obj.checkFileExistence );
                end
                obj.pipeline.setTestData( Core.IdentTrainPipeData.combineData( testFolds{:} ) );
            else
                dataFolds = cell( 1, numel( obj.dataFlists ) );
                for ii = 1 : numel( obj.dataFlists )
                    dataFolds{ii} = Core.IdentTrainPipeData();
                    dataFolds{ii}.loadFileList( obj.dataFlists{ii}, obj.checkFileExistence );
                end
                obj.pipeline.connectData( Core.IdentTrainPipeData.combineData( dataFolds{:} ) );
                obj.pipeline.splitIntoTrainAndTestSets( obj.trainsetShare );
            end
            obj.dataSetupAlreadyDone = true;
        end
        %% -------------------------------------------------------------------------------
        
    end

end
