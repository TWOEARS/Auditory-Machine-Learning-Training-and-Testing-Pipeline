classdef TwoEarsIdTrainPipe < handle

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        featureCreator = [];
        modelCreator = [];
        trainset = [];
        testset = [];
        data = [];
        trainsetShare = 0.5;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        pipeline;
        dataSetupAlreadyDone = false;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = TwoEarsIdTrainPipe( varargin )
            ip = inputParser;
            ip.addOptional( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
            ip.addOptional( 'soundDbBaseDir', '' );
            ip.parse( varargin{:} );
            modelTrainers.Base.featureMask( true, [] );
            fprintf( '\nmodelTrainers.Base.featureMask set to []\n' );
            obj.pipeline = core.IdentificationTrainingPipeline( ...
                                          'cacheSystemDir', ip.Results.cacheSystemDir, ...
                                          'soundDbBaseDir', ip.Results.soundDbBaseDir );
            obj.dataSetupAlreadyDone = false;
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj, sceneCfgs, varargin )
            ip = inputParser;
            ip.addOptional( 'hrir', ...
                            'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa', ...
                            @(fn)(exist( fn, 'file' )) );
            ip.parse( varargin{:} );
            obj.setupData( true );
            obj.pipeline.resetDataProcs();
            binSim = dataProcs.SceneEarSignalProc( ...
                                      dataProcs.IdSimConvRoomWrapper( ip.Results.hrir ) );
            if isempty( obj.featureCreator )
                obj.featureCreator = featureCreators.FeatureSet1Blockmean();
            end
            obj.pipeline.featureCreator = obj.featureCreator;
            multiCfgProcs{1} = dataProcs.MultiSceneCfgsIdProcWrapper( binSim, binSim );
            multiCfgProcs{2} = dataProcs.MultiSceneCfgsIdProcWrapper( ...
                binSim, ...
                dataProcs.ParallelRequestsAFEmodule( binSim.getDataFs(), ...
                                                     obj.featureCreator.getAFErequests() ) );
            multiCfgProcs{3} =  ...
                      dataProcs.MultiSceneCfgsIdProcWrapper( binSim, obj.featureCreator );
            multiCfgProcs{4} = dataProcs.MultiSceneCfgsIdProcWrapper( ...
                                                 binSim, dataProcs.GatherFeaturesProc() );
            for ii = 1 : numel( multiCfgProcs )
                multiCfgProcs{ii}.setSceneConfig( sceneCfgs );
                if ii == numel( multiCfgProcs ), continue; end
                obj.pipeline.addDataPipeProc( multiCfgProcs{ii} );
            end
            obj.pipeline.addGatherFeaturesProc( multiCfgProcs{end} );
            if isempty( obj.modelCreator )
                obj.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
                    'performanceMeasure', @performanceMeasures.BAC2, ...
                    'cvFolds', 4, ...
                    'alpha', 0.99 );
            end
            obj.pipeline.addModelCreator( obj.modelCreator );
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
            obj.dataSetupAlreadyDone = strcmp(obj.data,newData);
            obj.data = newData;
        end
        %% -------------------------------------------------------------------------------

        function setupData( obj, skipIfAlreadyDone )
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
