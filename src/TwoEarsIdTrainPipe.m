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
        binauralSim;
        multiCfgProcs;
        dataSetupAlreadyDone = false;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = TwoEarsIdTrainPipe( varargin )
            ip = inputParser;
            ip.addOptional( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
            ip.addOptional( 'soundDbBaseDir', '' );
            ip.addOptional( 'hrir', ...
                            'impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa', ...
                            @(fn)(exist( fn, 'file' )) );
            ip.parse( varargin{:} );
            modelTrainers.Base.featureMask( true, [] );
            fprintf( '\nmodelTrainers.Base.featureMask set to []\n' );
            obj.pipeline = core.IdentificationTrainingPipeline( ...
                                          'cacheSystemDir', ip.Results.cacheSystemDir, ...
                                          'soundDbBaseDir', ip.Results.soundDbBaseDir );
            binSim = dataProcs.IdSimConvRoomWrapper( ip.Results.hrir );
            obj.binauralSim = dataProcs.SceneEarSignalProc( binSim );
            obj.multiCfgProcs{1} = ...
                dataProcs.MultiSceneCfgsIdProcWrapper( obj.binauralSim, obj.binauralSim );
            obj.dataSetupAlreadyDone = false;
        end
        %% -------------------------------------------------------------------------------
        
        function init( obj )
            obj.setupData( true );
            if isempty( obj.featureCreator )
                obj.featureCreator = featureCreators.RatemapPlusDeltasBlockmean();
            end
            obj.pipeline.featureCreator = obj.featureCreator;
            obj.pipeline.resetDataProcs();
            obj.multiCfgProcs{2} = dataProcs.MultiSceneCfgsIdProcWrapper( ...
                obj.binauralSim, ...
                dataProcs.ParallelRequestsAFEmodule( obj.binauralSim.getDataFs(), ...
                                                     obj.featureCreator.getAFErequests() ...
                                                   ) );
            obj.multiCfgProcs{3} =  dataProcs.MultiSceneCfgsIdProcWrapper( ...
                                                    obj.binauralSim, obj.featureCreator );
            obj.multiCfgProcs{4} = dataProcs.MultiSceneCfgsIdProcWrapper( ...
                                        obj.binauralSim, dataProcs.GatherFeaturesProc() );
            obj.pipeline.addDataPipeProc( obj.multiCfgProcs{1} );
            obj.pipeline.addDataPipeProc( obj.multiCfgProcs{2} );
            obj.pipeline.addDataPipeProc( obj.multiCfgProcs{3} );
            obj.pipeline.addGatherFeaturesProc( obj.multiCfgProcs{4} );
            if isempty( obj.modelCreator )
                obj.modelCreator = modelTrainers.GlmNetLambdaSelectTrainer( ...
                    'performanceMeasure', @performanceMeasures.BAC2, ...
                    'cvFolds', 4, ...
                    'alpha', 0.99 );
            end
            obj.pipeline.addModelCreator( obj.modelCreator );
        end
        %% -------------------------------------------------------------------------------

        function setSceneConfig( obj, sceneCfgs )
            for ii = 1 : numel( obj.multiCfgProcs )
                obj.multiCfgProcs{ii}.setSceneConfig( sceneCfgs );
            end
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
