classdef TwoEarsNIstandardIdPipeline < handle

    properties
        pipeline;
        binauralSim;
        multiConfBinauralSim;
        featureCreator;
        afeModule;
        multiConfAFEmodule;
    end
    
    methods
        
        function obj = TwoEarsNIstandardIdPipeline( wavflist, featureCreator, modelCreator )
            obj.pipeline = IdentificationTrainingPipeline();
            obj.pipeline.loadWavFileList( wavflist );
            obj.binauralSim = IdSimConvRoomWrapper();
            obj.multiConfBinauralSim = MultiConfigurationsEarSignalProc( obj.binauralSim );
            obj.multiConfBinauralSim.setSceneConfig( SceneConfiguration() );
            obj.featureCreator = featureCreator;
            obj.afeModule = AuditoryFEmodule( ...
                obj.binauralSim.getDataFs(), obj.featureCreator.getAFErequests() );
            obj.multiConfAFEmodule = MultiConfigurationsAFEmodule( obj.afeModule );

            obj.pipeline.addDataPipeProc( obj.multiConfBinauralSim );
            obj.pipeline.addDataPipeProc( obj.multiConfAFEmodule );
            obj.pipeline.addDataPipeProc( ...
                MultiConfigurationsFeatureProc( IdFeatureProc( obj.featureCreator ) ) );

            obj.pipeline.addGatherFeaturesProc( GatherFeaturesProc() );
            
            obj.pipeline.addModelCreator( modelCreator );
        end
        
        function setMultiSceneConfigs( obj, sceneConfigs )
            obj.multiConfBinauralSim.setSceneConfig( sceneConfigs );
        end

        function run( obj, models, trainSetShare, nGenAssessFolds )
            obj.pipeline.run( models, trainSetShare, nGenAssessFolds );
        end
        
    end

end
