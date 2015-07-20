function modelPath = idtestCleanAzmVar( classname, testFlist, modelPath, azm )

testpipe = TwoEarsIdTrainPipe();
m = load( fullfile( modelPath, [classname '.model.mat'] ) );
testpipe.featureCreator = m.featureCreator;
testpipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelPath, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2, ...
        'modelParams', struct('lambda', []) );
testpipe.modelCreator.verbose( 'on' );

testpipe.testset = testFlist;

sc = dataProcs.SceneConfiguration(); % clean
sc.angleSignal = dataProcs.ValGen('manual', [azm]);
testpipe.setSceneConfig( [sc] ); 

testpipe.init();
modelPath = testpipe.pipeline.run( {classname}, 0 );

end
