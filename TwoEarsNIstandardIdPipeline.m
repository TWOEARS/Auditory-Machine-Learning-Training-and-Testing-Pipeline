classdef TwoEarsNIstandardIdPipeline < handle

    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        pipeline;
        multiConfBinauralSim;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = TwoEarsNIstandardIdPipeline( data, trainSetShare, featureCreator, modelCreator )
            obj.pipeline = core.IdentificationTrainingPipeline();

            obj.pipeline.connectData( data );
            obj.pipeline.splitIntoTrainAndTestSets( trainSetShare );
            
            binauralSim = dataProcs.IdSimConvRoomWrapper();
            obj.multiConfBinauralSim = dataProcs.MultiConfigurationsEarSignalProc( binauralSim );
            obj.multiConfBinauralSim.setSceneConfig( dataProcs.SceneConfiguration() );

            obj.pipeline.featureCreator = featureCreator;
            
            multiConfAFEmodule = dataProcs.MultiConfigurationsAFEmodule( dataProcs.AuditoryFEmodule( ...
                binauralSim.getDataFs(), featureCreator.getAFErequests() ) );

            obj.pipeline.addDataPipeProc( obj.multiConfBinauralSim );
            obj.pipeline.addDataPipeProc( multiConfAFEmodule );
            obj.pipeline.addDataPipeProc( ...
                dataProcs.MultiConfigurationsFeatureProc( featureCreator ) );
            obj.pipeline.addGatherFeaturesProc( core.GatherFeaturesProc() );
            
            obj.pipeline.addModelCreator( modelCreator );
        end
        %% -------------------------------------------------------------------------------
        
    end

end
