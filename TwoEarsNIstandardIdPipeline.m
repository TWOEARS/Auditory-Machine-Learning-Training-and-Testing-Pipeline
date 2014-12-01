classdef TwoEarsNIstandardIdPipeline < handle

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        pipeline;
        multiConfBinauralSim;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = TwoEarsNIstandardIdPipeline( wavflist, trainSetShare, featureCreator, modelCreator )
            obj.pipeline = IdentificationTrainingPipeline();

            obj.pipeline.loadWavFileList( wavflist );
            obj.pipeline.splitIntoTrainAndTestSets( trainSetShare );
            
            binauralSim = IdSimConvRoomWrapper();
            obj.multiConfBinauralSim = MultiConfigurationsEarSignalProc( binauralSim );
            obj.multiConfBinauralSim.setSceneConfig( SceneConfiguration() );

            obj.pipeline.featureCreator = featureCreator;
            
            multiConfAFEmodule = MultiConfigurationsAFEmodule( AuditoryFEmodule( ...
                binauralSim.getDataFs(), featureCreator.getAFErequests() ) );

            obj.pipeline.addDataPipeProc( obj.multiConfBinauralSim );
            obj.pipeline.addDataPipeProc( multiConfAFEmodule );
            obj.pipeline.addDataPipeProc( ...
                MultiConfigurationsFeatureProc( IdFeatureProc( featureCreator ) ) );
            obj.pipeline.addGatherFeaturesProc( GatherFeaturesProc() );
            
            obj.pipeline.addModelCreator( modelCreator );
        end
        %% -------------------------------------------------------------------------------
        
    end

end
