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
        featureCreator = [];    % feature extraction (default: featureCreators.RatemapPlusDeltasBlockmean())
        modelCreator = [];      % model trainer
        trainset = [];          % file list with train examples
        testset = [];           % file list with test examples
        data = [];              % list of files to split in train and test
        trainsetShare = 0.5;
    end
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        pipeline;
        binauralSim;                    % binaural simulator
        sceneConfBinauralSim;           % ?
        multiConfBinauralSim;           % ?
        dataSetupAlreadyDone = false;   % pre-processing steps already done.
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = TwoEarsIdTrainPipe( hrir )
            % TwoEarsIdTrainPipe Construct a training pipeline
            %   TwoEarsIdTrainPipe() instantiate using the default impulse
            %   response dataset to drive the binaural simulator
            %   TwoEarsIdTrainPipe( hrir ) instantiate using a path to the 
            %   impulse response dataset defined by hrir
            %   (e.g. 'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa'
            %
            if nargin < 1
                hrir = 'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa';
            end
            modelTrainers.Base.featureMask( true, [] ); % reset the feature mask
            warning( 'modelTrainers.Base.featureMask set to []' );
            obj.pipeline = core.IdentificationTrainingPipeline(); % ?
            obj.binauralSim = dataProcs.IdSimConvRoomWrapper( hrir );
            obj.sceneConfBinauralSim = ...
                dataProcs.SceneEarSignalProc( obj.binauralSim );
            obj.multiConfBinauralSim = ...
                dataProcs.MultiConfigurationsEarSignalProc( obj.sceneConfBinauralSim );
%             obj.init();
            obj.dataSetupAlreadyDone = false;
        end
        %% -------------------------------------------------------------------------------

        function setSceneConfig( obj, scArray )
            obj.multiConfBinauralSim.setSceneConfig( scArray );
        end
        %% -------------------------------------------------------------------------------

        function set.trainset( obj, newTrainset )
            obj.dataSetupAlreadyDone = strcmp(obj.trainset,newTrainset);
            obj.trainset = newTrainset;
        end
        %% -------------------------------------------------------------------------------

        function set.testset( obj, newTestset )
            obj.dataSetupAlreadyDone = strcmp(obj.testset,newTestset);
            obj.testset = newTestset;
        end
        %% -------------------------------------------------------------------------------

        function set.data( obj, newData )
            % set the data to be split into train and test set by the
            % pipeline
            obj.dataSetupAlreadyDone = strcmp(obj.data,newData);
            obj.data = newData;
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj )
            obj.setupData( true );
            if isempty( obj.featureCreator )
                % default feature creator
                obj.featureCreator = featureCreators.RatemapPlusDeltasBlockmean();
            end
            obj.pipeline.featureCreator = obj.featureCreator;
            obj.pipeline.resetDataProcs();
            obj.pipeline.addDataPipeProc( obj.multiConfBinauralSim );
            obj.pipeline.addDataPipeProc( ...
                dataProcs.MultiConfigurationsAFEmodule( ...
                    dataProcs.ParallelRequestsAFEmodule( ...
                        obj.binauralSim.getDataFs(), ...
                        obj.featureCreator.getAFErequests() ...
                        ) ) );
            obj.pipeline.addDataPipeProc( ...
                dataProcs.MultiConfigurationsFeatureProc( obj.featureCreator ) );
            obj.pipeline.addGatherFeaturesProc( core.GatherFeaturesProc() );
            if isempty( obj.modelCreator )
                obj.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
                    'performanceMeasure', @performanceMeasures.BAC2, ...
                    'cvFolds', 4, ...
                    'alpha', 0.99 );
            end
            obj.pipeline.addModelCreator( obj.modelCreator );
        end
        %% -------------------------------------------------------------------------------

        function setupData( obj, skipIfAlreadyDone )
            % setupData set up the train and test set and perform a
            % train/test split on the data if not already specified.
            if nargin > 1 && skipIfAlreadyDone && obj.dataSetupAlreadyDone
                return;
            end
            if ~isempty( obj.trainset ) || ~isempty( obj.testset )
                trainSet = core.IdentTrainPipeData();
                trainSet.loadWavFileList( obj.trainset );
                obj.pipeline.setTrainData( trainSet );
                testSet = core.IdentTrainPipeData();
                testSet.loadWavFileList( obj.testset );
                obj.pipeline.setTestData( testSet );
            else
                data = core.IdentTrainPipeData();
                data.loadWavFileList( obj.data );
                obj.pipeline.connectData( data );
                obj.pipeline.splitIntoTrainAndTestSets( obj.trainsetShare );
            end
            obj.dataSetupAlreadyDone = true;
        end
        %% -------------------------------------------------------------------------------
        
    end

end
