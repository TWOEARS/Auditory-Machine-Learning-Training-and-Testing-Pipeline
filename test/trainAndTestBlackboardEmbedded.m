function trainAndTestBlackboardEmbedded( modelpath_, classIdx, execBaseline )

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();

classes = {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'},{'crash'},{'dog'},...
           {'engine'},{'footsteps'},{'knock'},{'phone'},{'piano'},...
           {'maleSpeech'},{'femaleScream','maleScream'}};
for ii = 1 : numel( classes )
    labelCreators{ii,1} = 'LabelCreators.MultiEventTypeLabeler'; %#ok<AGROW>
    labelCreators{ii,2} = {'types', classes(ii), ...
                           'negOut', 'rest', ...
                           'srcTypeFilterOut', [2,1;3,1;4,1]}; %#ok<AGROW> % target sounds only on source 1
end

if nargin < 2 || isempty( classIdx )
    classIdx = 2;
end
if nargin < 3 || isempty( execBaseline )
    execBaseline = false;
end

if ~execBaseline
    modelname = 'bbsEmbModel';
    modelpath = 'test_bbsEmbedded';
else
    modelname = 'bbsEmbModel_baselineCmp';
    modelpath = 'test_bbsEmbedded_baselineCmp';
end

%% define blackboard

if ~execBaseline
    % setup blackboard system to be embedded into pipe
    bbs = BlackboardSystem(1);
    idModels = setDefaultIdModels();
    afeCon = BlackboardEmbedding.AuditoryFrontEndConnection(16000);
    bbs.setRobotConnect(afeCon);
    bbs.setDataConnect('AuditoryFrontEndBridgeKS', [], 0.2);
    ppRemoveDc = false;
    for ii = 1 : numel( idModels )
        idKss{ii} = bbs.createKS('IdentityKS', {idModels(ii).name, idModels(ii).dir, ppRemoveDc});
        idKss{ii}.setInvocationFrequency(10);
    end
    bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', 'AgendaEmpty' );
    bbs.blackboardMonitor.bind({bbs.dataConnect}, idKss, 'replaceOld' );
end

%% train

if nargin < 1 || isempty( modelpath_ )

pipe = TwoEarsIdTrainPipe();
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 1.0, 1./3 );
if ~execBaseline
    % embed blackboard system into pipe    
    pipe.blackboardSystem = DataProcs.BlackboardSystemWrapper( bbs );
end
pipe.featureCreator = FeatureCreators.FeatureSet5aBlockmean();
pipe.labelCreator = feval( labelCreators{classIdx,1}, labelCreators{classIdx,2}{:} );
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.ImportanceWeightedSquareBalancedAccuracy, ...
    'maxDataSize', 5000, ...
    'dataSelector', DataSelectors.BAC_Selector(), ...
    'importanceWeighter', ImportanceWeighters.BAC_Weighter(), ...
    'cvFolds', 4, ...
    'alpha', 0.99 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_miniMini_TrainSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
    'azimuth',SceneConfig.ValGen('manual',45), ...
    'data', SceneConfig.FileListValGen( 'pipeInput' ) )...
    );
sc(1).addSource( SceneConfig.PointSource( ...
    'azimuth',SceneConfig.ValGen('manual',-45), ...
    'data', SceneConfig.FileListValGen( pipe.pipeline.trainSet(:,'fileName') ),...
    'offset', SceneConfig.ValGen( 'manual', 0.25 ) ), ...
    'snr', SceneConfig.ValGen( 'manual', 0 ),...
    'loop', 'randomSeq' ...
    );
sc(1).setLengthRef( 'source', 1, 'min', 30 );
sc(1).setSceneNormalization( true, 1 );
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource( ...
    'azimuth',SceneConfig.ValGen('manual',90), ...
    'data', SceneConfig.FileListValGen( 'pipeInput' ) )...
    );
sc(2).addSource( SceneConfig.PointSource( ...
    'azimuth',SceneConfig.ValGen('manual',0), ...
    'data', SceneConfig.FileListValGen( pipe.pipeline.trainSet(:,'fileName') ),...
    'offset', SceneConfig.ValGen( 'manual', 0.25 ) ), ...
    'snr', SceneConfig.ValGen( 'manual', -10 ),...
    'loop', 'randomSeq' ...
    );
sc(2).setLengthRef( 'source', 1, 'min', 30 );
sc(2).setSceneNormalization( true, 1 );

pipe.init( sc, 'fs', 16000, 'loadBlockAnnotations', true, ...
           'sceneCfgDataUseRatio', 1.0, 'sceneCfgPrioDataUseRatio', 1.0, ...
           'dataSelector', DataSelectors.BAC_Selector(), 'selectPrioClass', +1 );

modelpath_ = pipe.pipeline.run( 'modelName', modelname, 'modelPath', modelpath, ...
                               'debug', true  );

fprintf( ' -- Model is saved at %s -- \n\n', modelpath_ );

end

%% test

pipe = TwoEarsIdTrainPipe();
pipe.blockCreator = BlockCreators.MeanStandardBlockCreator( 1.0, 1./3 );
if ~execBaseline
    % embed blackboard system into pipe, maybe like:
    % pipe.blackboard = DataProcs.BlackboardWrapper( identify200msBlocksBlackboard );
    pipe.featureCreator = FeatureCreators.BBS_FullstreamIdProbs();
else
    pipe.featureCreator = FeatureCreators.FeatureSet5aBlockmean();
end
pipe.labelCreator = feval( labelCreators{classIdx,1}, labelCreators{classIdx,2}{:} );
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( ...
    [pwd filesep modelpath filesep modelname '.model.mat'], ...
    'performanceMeasure', @PerformanceMeasures.BAC_BAextended );
pipe.modelCreator.verbose( 'on' );

pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_miniMini_TestSet_1.flist';
pipe.setupData();

sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
    'azimuth',SceneConfig.ValGen('manual',45), ...
    'data', SceneConfig.FileListValGen( 'pipeInput' ) )...
    );
sc(1).addSource( SceneConfig.PointSource( ...
    'azimuth',SceneConfig.ValGen('manual',-45), ...
    'data', SceneConfig.FileListValGen( pipe.pipeline.testSet(:,'fileName') ),...
    'offset', SceneConfig.ValGen( 'manual', 0.25 ) ), ...
    'snr', SceneConfig.ValGen( 'manual', 0 ),...
    'loop', 'randomSeq' ...
    );
sc(1).setLengthRef( 'source', 1, 'min', 30 );
sc(1).setSceneNormalization( true, 1 );
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource( ...
    'azimuth',SceneConfig.ValGen('manual',90), ...
    'data', SceneConfig.FileListValGen( 'pipeInput' ) )...
    );
sc(2).addSource( SceneConfig.PointSource( ...
    'azimuth',SceneConfig.ValGen('manual',0), ...
    'data', SceneConfig.FileListValGen( pipe.pipeline.testSet(:,'fileName') ),...
    'offset', SceneConfig.ValGen( 'manual', 0.25 ) ), ...
    'snr', SceneConfig.ValGen( 'manual', -10 ),...
    'loop', 'randomSeq' ...
    );
sc(2).setLengthRef( 'source', 1, 'min', 30 );
sc(2).setSceneNormalization( true, 1 );

pipe.init( sc, 'fs', 16000, 'loadBlockAnnotations', true, ...
           'sceneCfgDataUseRatio', 1.0, 'sceneCfgPrioDataUseRatio', 1.0, ...
           'dataSelector', DataSelectors.BAC_Selector(), 'selectPrioClass', +1 );

[modelpath_,~,testPerfresults] = ...
             pipe.pipeline.run( 'modelName', modelname, 'modelPath', modelpath, ...
                                'debug', true  );

fprintf( ' -- Model is saved at %s -- \n\n', modelpath_ );

end
