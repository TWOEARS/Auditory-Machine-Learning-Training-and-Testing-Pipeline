function modelPath = idtrainCleanGMMnet( classname, wavflist, trainWavflist, testWavflist )

%% init pathes
startTwoEars( '../../src/identificationTraining/identTraining_repos.xml' );

if exist( 'trainWavflist', 'var' ) && exist( 'testWavflist', 'var' )
    trainSet = IdentTrainPipeData();
    trainSet.loadWavFileList( trainWavflist );
    testSet = IdentTrainPipeData();
    testSet.loadWavFileList( testWavflist );
else
    if ~exist( 'wavflist', 'var' )
        wavflist = 'all.flist';
    end
    data = IdentTrainPipeData();
    data.loadWavFileList( wavflist );
    [trainSet, testSet] = data.getShare( 0.7 );
    trainSet.saveDataFList( 'newTrainSet.flist' );
    testSet.saveDataFList( 'newTestSet.flist' );
end

%% create training pipeline
featureCreator = FeatureSet1Blockmean();
modelCreator = GMMmodelSelectTrainer( ...
                    'performanceMeasure', @BAC2,...
                    'thr', (0.85:.1:0.9),'nComp',(4:1:6));
% modelCreator =  GlmNetLambdaSelectTrainer( ...
%                     'performanceMeasure', @BAC2 );
               
modelCreator.verbose( 'on' );

trainpipe = TwoEarsNIstandardIdPipeline( trainSet, 1, featureCreator, modelCreator );

sc = SceneConfiguration(); % clean

trainpipe.multiConfBinauralSim.setSceneConfig( [sc] ); 

%% run training pipeline
modelPath = trainpipe.pipeline.run( {classname}, 0 );

end

