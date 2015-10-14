function genGenOvrl( fc, fl )

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = fc;
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = fl;
pipe.trainsetShare = 1;
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', -10 ));
pipe.setSceneConfig( sc ); 

pipe.init();
pipe.pipeline.run( {'donttrain'}, 0 );


pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = fc;
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = fl;
pipe.trainsetShare = 1;
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 0 ));
pipe.setSceneConfig( sc ); 

pipe.init();
pipe.pipeline.run( {'donttrain'}, 0 );


% pipe = TwoEarsIdTrainPipe();
% pipe.featureCreator = fc;
% pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
% pipe.modelCreator.verbose( 'on' );
% 
% pipe.data = fl;
% pipe.trainsetShare = 1;
% pipe.setupData();
% 
% sc = sceneConfig.SceneConfiguration();
% sc.addSource( sceneConfig.PointSource() );
% sc.addSource( sceneConfig.PointSource( ...
%     'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
%     sceneConfig.ValGen( 'manual', 5 ));
% pipe.setSceneConfig( sc ); 
% 
% pipe.init();
% pipe.pipeline.run( {'donttrain'}, 0 );


pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = fc;
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = fl;
pipe.trainsetShare = 1;
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 10 ));
pipe.setSceneConfig( sc ); 

pipe.init();
pipe.pipeline.run( {'donttrain'}, 0 );


pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = fc;
pipe.modelCreator = modelTrainers.LoadModelNoopTrainer( 'noop' );
pipe.modelCreator.verbose( 'on' );

pipe.data = fl;
pipe.trainsetShare = 1;
pipe.setupData();

sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource() );
sc.addSource( sceneConfig.PointSource( ...
    'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')) ),...
    sceneConfig.ValGen( 'manual', 20 ));
pipe.setSceneConfig( sc ); 

pipe.init();
pipe.pipeline.run( {'donttrain'}, 0 );


end
