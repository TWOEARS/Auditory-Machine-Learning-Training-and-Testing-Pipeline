function idtestRandomSimRoom( classname, testFlist, modelPath )

testpipe = TwoEarsIdTrainPipe();
m = load( fullfile( modelPath, [classname '.model.mat'] ) );
testpipe.featureCreator = m.featureCreator;
testpipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelPath, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2 ...
        );
testpipe.modelCreator.verbose( 'on' );

testpipe.testset = testFlist;

sc = sceneConfig.SceneConfiguration();
sc.angleSignal = sceneConfig.ValGen('random', [0,359.9]);
sc.distSignal = sceneConfig.ValGen('random', [0.5,3]);
wall.front = sceneConfig.ValGen('random', [3,5]);
wall.back = sceneConfig.ValGen('random', [-3,-5]);
wall.right = sceneConfig.ValGen('random', [-3,-5]);
wall.left = sceneConfig.ValGen('random', [3,5]);
wall.height = sceneConfig.ValGen('random', [2,3]);
wall.rt60 = sceneConfig.ValGen('random', [1,8]);
sc.addWalls( sceneConfig.WallsValGen(wall) );

testpipe.setSceneConfig( [sc] ); 

testpipe.init();
testpipe.pipeline.run( {classname}, 0 );

end
