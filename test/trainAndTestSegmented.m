function trainAndTestSegmented( modelPath )

addPathsIfNotIncluded( cleanPathFromRelativeRefs( [pwd '/..'] ) ); 
startAMLTTP();
addPathsIfNotIncluded( {...
    cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/src'] ), ... 
    cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/external/data-hash'] ), ...
    cleanPathFromRelativeRefs( [pwd '/../../segmentation-training-pipeline/external/yaml-matlab'] ) ...
    } );
segmModelFileName = '70c4feac861e382413b4c4bfbf895695.mat';
mkdir( fullfile( db.tmp, 'learned_models', 'SegmentationKS' ) );
copyfile( ['./' segmModelFileName], ...
          fullfile( db.tmp, 'learned_models', 'SegmentationKS', segmModelFileName ), ...
          'f' );

%% train

if nargin < 1 || isempty( modelPath )
    
pipe = TwoEarsIdTrainPipe();
pipe.ksWrapper = DataProcs.SegmentKsWrapper( ...
    'SegmentationTrainerParameters5.yaml', ...
    'useDnnLocKs', false, ...
    'useNsrcsKs', false, ...
    'segSrcAssignmentMethod', 'minPermutedDistance', ...
    'varAzmSigma', 0, ...
    'nsrcsBias', 0, ...
    'nsrcsRndPlusMinusBias', 0 );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
babyLabeler = LabelCreators.MultiEventTypeLabeler( 'types', {{'baby'}}, 'negOut', 'rest' );
pipe.labelCreator = babyLabeler;
pipe.modelCreator = ModelTrainers.GlmNetLambdaSelectTrainer( ...
    'performanceMeasure', @PerformanceMeasures.BAC2, ...
    'cvFolds', 4, ...
    'alpha', 0.99, 'maxDataSize', 1000 );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_miniMini_TrainSet_1.flist';
pipe.setupData();

sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ), ...
        'azimuth', SceneConfig.ValGen( 'manual', -45 ) )  );
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ), ...
        'azimuth', SceneConfig.ValGen( 'manual', +45 )  ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ), ...
        'azimuth', SceneConfig.ValGen( 'manual', +135 )  ),...
    'snr', SceneConfig.ValGen( 'manual', -10 ),...
    'loop', 'randomSeq' );
sc(1) = SceneConfig.SceneConfiguration();
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ), ...
        'azimuth', SceneConfig.ValGen( 'manual', -45 ) )  );
sc(1).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.trainSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ), ...
        'azimuth', SceneConfig.ValGen( 'manual', +45 )  ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
sc(1).addSource( SceneConfig.DiffuseSource( ...
        'offset', SceneConfig.ValGen( 'manual', 0 )  ),...
    'snr', SceneConfig.ValGen( 'manual', 0 ) );
pipe.init( sc, 'fs', 16000 );

modelPath = pipe.pipeline.run( 'modelName', 'segmModel', 'modelPath', 'test_segmented' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

end

%% test

pipe = TwoEarsIdTrainPipe();
pipe.ksWrapper = DataProcs.SegmentKsWrapper( ...
    'SegmentationTrainerParameters5.yaml', ...
    'useDnnLocKs', false, ...
    'useNsrcsKs', false, ...
    'segSrcAssignmentMethod', 'minPermutedDistance', ...
    'varAzmSigma', 0, ...
    'nsrcsBias', 0, ...
    'nsrcsRndPlusMinusBias', 2 );
pipe.featureCreator = FeatureCreators.FeatureSet5Blockmean();
babyLabeler = LabelCreators.MultiEventTypeLabeler( 'types', {{'baby'}}, 'negOut', 'rest' );
pipe.labelCreator = babyLabeler;
pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( ...
    [pwd filesep 'test_segmented/segmModel.model.mat'], ...
    'performanceMeasure', @PerformanceMeasures.BAC );
pipe.modelCreator.verbose( 'on' );

pipe.testset = 'learned_models/IdentityKS/trainTestSets/NIGENS160807_miniMini_TestSet_1.flist';
pipe.setupData();

sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ), ...
        'azimuth', SceneConfig.ValGen( 'manual', -45 )   )  );
sc.addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.testSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ), ...
        'azimuth', SceneConfig.ValGen( 'manual', +45 )  ),...
    'snr', SceneConfig.ValGen( 'manual', 0 ),...
    'loop', 'randomSeq' );
sc(2) = SceneConfig.SceneConfiguration();
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( 'pipeInput' ), ...
        'azimuth', SceneConfig.ValGen( 'manual', -45 ) )  );
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.testSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ), ...
        'azimuth', SceneConfig.ValGen( 'manual', +45 )  ),...
    'snr', SceneConfig.ValGen( 'manual', 10 ),...
    'loop', 'randomSeq' );
sc(2).addSource( SceneConfig.PointSource( ...
        'data', SceneConfig.FileListValGen( ...
               pipe.pipeline.testSet('fileLabel',{{'type',{'general'}}},'fileName') ),...
        'offset', SceneConfig.ValGen( 'manual', 0 ), ...
        'azimuth', SceneConfig.ValGen( 'manual', +135 )  ),...
    'snr', SceneConfig.ValGen( 'manual', -10 ),...
    'loop', 'randomSeq' );
pipe.init( sc, 'fs', 16000 );

[modelPath,~,testPerfresults] = ...
             pipe.pipeline.run( 'modelName', 'segmModel', 'modelPath', 'test_segmented' );

fprintf( ' -- Model is saved at %s -- \n\n', modelPath );

%% analysis

resc = int32( zeros(0,0,0,0,0,0,0,0,0,0,0) );
resct = int32( zeros(0,0,0,0,0,0,0,0,0,0,0) );
fprintf( 'analyzing' );
for ii = 1 : numel( testPerfresults.datapointInfo.blockAnnotsCacheFiles )
    dpiIdxs = find( testPerfresults.datapointInfo.fileIdxs == ii );
    for jj = 1 : numel( testPerfresults.datapointInfo.blockAnnotsCacheFiles{ii} )
        dpiIdxs_ = find( testPerfresults.datapointInfo.bacfIdxs(dpiIdxs) == jj );
        dpiIdxs_ = dpiIdxs(dpiIdxs_);
        dpiIdxs__ = testPerfresults.datapointInfo.bIdxs(dpiIdxs_);
        blockAnnotations = load( testPerfresults.datapointInfo.blockAnnotsCacheFiles{ii}{jj}, 'blockAnnotations');
        blockAnnotations = blockAnnotations.blockAnnotations;
        blockAnnotations = blockAnnotations(dpiIdxs__);
        yp = testPerfresults.datapointInfo.yPred(dpiIdxs_);
        yt = testPerfresults.datapointInfo.yTrue(dpiIdxs_);
        estAzms = [blockAnnotations.estAzm];
        gtAzms = cellfun( @(x)([x nan]), {blockAnnotations.srcAzms}, 'UniformOutput', false );
        azmErrTpFn = round( abs( wrapTo180( cellfun( @(x)(x(1)), gtAzms ) - estAzms ) )/5 ) + 2;
        azmErrTnFp = round( abs( wrapTo180( cellfun( @(x)(nanMean(x)), gtAzms ) - estAzms ) )/5 ) + 2;
        azmErr = (yt > 0)' .* azmErrTpFn + (yt < 0)' .* azmErrTnFp;
        azmErr(isnan(azmErr)) = 1;
        azmErr(isinf(azmErr)) = 1;
        nEstErr = [blockAnnotations.nSrcs_estimationError] + 4;
        nAct = [blockAnnotations.nSrcs_active] + 1;
        curNrj = cellfun( @(x)(max([x{:} single(-inf)])), {blockAnnotations.srcEnergy}, 'UniformOutput', false );
        targetHasEnergy = cellfun( @(x)(x > -40), curNrj, 'UniformOutput', true ) + 1;
        curSnr = cellfun( @(x)([x{:} nan]), {blockAnnotations.srcSNR}, 'UniformOutput', false );
        curSnrTpFn = round( max( cellfun( @(x)(single( x(1) )), curSnr ), -40 )/5 ) + 10;
        curSnrTnFp = round( max( cellfun( @(x)(nanMean(single( x ))), curSnr ), -40 )/5 ) + 10;
        curSnrTpFn(cellfun( @(x)(isnan(x(1))), curSnr )) = single( nan );
        curSnrTnFp(cellfun( @(x)(isnan(x(1))), curSnr )) = single( nan );
        curSnr = (yt > 0)' .* curSnrTpFn + (yt < 0)' .* curSnrTnFp;
        curSnr(isinf(curSnr)) = 1;
        curSnr(isnan(curSnr)) = 1;
        curSnr_avgSelf = cellfun( @(x)([x{:} nan]), {blockAnnotations.srcSNR_avgSelf}, 'UniformOutput', false );
        curSnr_avgSelfTpFn = round( max( cellfun( @(x)(single( x(1) )), curSnr_avgSelf ), -40 )/5 ) + 10;
        curSnr_avgSelfTnFp = round( max( cellfun( @(x)(nanMean(single( x ))), curSnr_avgSelf ), -40 )/5 ) + 10;
        curSnr_avgSelfTpFn(cellfun( @(x)(isnan(x(1))), curSnr_avgSelf )) = single( nan );
        curSnr_avgSelfTnFp(cellfun( @(x)(isnan(x(1))), curSnr_avgSelf )) = single( nan );
        curSnr_avgSelf = (yt > 0)' .* curSnr_avgSelfTpFn + (yt < 0)' .* curSnr_avgSelfTnFp;
        curSnr_avgSelf(isinf(curSnr_avgSelf)) = 1;
        curSnr_avgSelf(isnan(curSnr_avgSelf)) = 1;
        tp = (yp == yt) & (yp > 0);
        tn = (yp == yt) & (yp < 0);
        fp = (yp ~= yt) & (yp > 0);
        fn = (yp ~= yt) & (yp < 0);
        if any( size( resc ) < [1,1,1,1,max(targetHasEnergy),max(nAct(~isinf(nAct))),max(curSnr(~isinf(curSnr))),max(curSnr_avgSelf(~isinf(curSnr_avgSelf))),max(azmErr(~isinf(azmErr))),max(nEstErr(~isinf(nEstErr))),4] )
            resc(1,1,1,1,max(targetHasEnergy),max(nAct(~isinf(nAct))),max(curSnr(~isinf(curSnr))),max(curSnr_avgSelf(~isinf(curSnr_avgSelf))),max(azmErr(~isinf(azmErr))),max(nEstErr(~isinf(nEstErr))),4) = 0;
        end
        [C,~,ic] = unique( [targetHasEnergy;nAct;curSnr;curSnr_avgSelf;azmErr;nEstErr;tp']', 'rows' );
        mult = arrayfun(@(x)(sum(x==ic)), 1:size(C,1));
        oneIdxs = ones(size(C(:,1)));
        linIdxs = sub2ind(size(resc),oneIdxs,oneIdxs,oneIdxs,oneIdxs,C(:,1),C(:,2),C(:,3),C(:,4),C(:,5),C(:,6),oneIdxs);
        resc(linIdxs) = resc(linIdxs) + int32( C(:,7).*mult' );
        [C,~,ic] = unique( [targetHasEnergy;nAct;curSnr;curSnr_avgSelf;azmErr;nEstErr;tn']', 'rows' );
        mult = arrayfun(@(x)(sum(x==ic)), 1:size(C,1));
        oneIdxs = ones(size(C(:,1)));
        linIdxs = sub2ind(size(resc),oneIdxs,oneIdxs,oneIdxs,oneIdxs,C(:,1),C(:,2),C(:,3),C(:,4),C(:,5),C(:,6),oneIdxs*2);
        resc(linIdxs) = resc(linIdxs) + int32( C(:,7).*mult' );
        [C,~,ic] = unique( [targetHasEnergy;nAct;curSnr;curSnr_avgSelf;azmErr;nEstErr;fp']', 'rows' );
        mult = arrayfun(@(x)(sum(x==ic)), 1:size(C,1));
        oneIdxs = ones(size(C(:,1)));
        linIdxs = sub2ind(size(resc),oneIdxs,oneIdxs,oneIdxs,oneIdxs,C(:,1),C(:,2),C(:,3),C(:,4),C(:,5),C(:,6),oneIdxs*3);
        resc(linIdxs) = resc(linIdxs) + int32( C(:,7).*mult' );
        [C,~,ic] = unique( [targetHasEnergy;nAct;curSnr;curSnr_avgSelf;azmErr;nEstErr;fn']', 'rows' );
        mult = arrayfun(@(x)(sum(x==ic)), 1:size(C,1));
        oneIdxs = ones(size(C(:,1)));
        linIdxs = sub2ind(size(resc),oneIdxs,oneIdxs,oneIdxs,oneIdxs,C(:,1),C(:,2),C(:,3),C(:,4),C(:,5),C(:,6),oneIdxs*4);
        resc(linIdxs) = resc(linIdxs) + int32( C(:,7).*mult' );
        fprintf( '.' );
        
        [~,~,sidxs] = unique( [blockAnnotations.blockOffset] );
        counts = struct( 'yp', num2cell(yp), 'yt', num2cell(yt) );
        for bb = 1 : max( sidxs )
            [aBAs, aCs] = aggregateBlockAnnotations( blockAnnotations(sidxs == bb), counts(sidxs == bb) );
            if ~exist( 'aggrBAs', 'var' )
                aggrBAs(1) = aBAs;
                aggrCounts(1) = aCs;
            else
                aggrBAs(end+1) = aBAs;
                aggrCounts(end+1) = aCs;
            end
        end
        targetHasEnergy = [aggrBAs.targetHasEnergy];
        nAct = [aggrBAs.nAct];
        curSnr = [aggrBAs.curSnr];
        curSnr_avgSelf = [aggrBAs.curSnr_avgSelf];
        azmErr = [aggrBAs.azmErr];
        nEstErr = [aggrBAs.nEstErr];
        tp = [aggrCounts.tp];
        tn = [aggrCounts.tn];
        fp = [aggrCounts.fp];
        fn = [aggrCounts.fn];
        if any( size( resct ) < [1,1,1,1,max(targetHasEnergy),max(nAct(~isinf(nAct))),max(curSnr(~isinf(curSnr))),max(curSnr_avgSelf(~isinf(curSnr_avgSelf))),max(azmErr(~isinf(azmErr))),max(nEstErr(~isinf(nEstErr))),4] )
            resct(1,1,1,1,max(targetHasEnergy),max(nAct(~isinf(nAct))),max(curSnr(~isinf(curSnr))),max(curSnr_avgSelf(~isinf(curSnr_avgSelf))),max(azmErr(~isinf(azmErr))),max(nEstErr(~isinf(nEstErr))),4) = 0;
        end
        [C,~,ic] = unique( [targetHasEnergy;nAct;curSnr;curSnr_avgSelf;azmErr;nEstErr;tp]', 'rows' );
        mult = arrayfun(@(x)(sum(x==ic)), 1:size(C,1));
        oneIdxs = ones(size(C(:,1)));
        linIdxs = sub2ind(size(resct),oneIdxs,oneIdxs,oneIdxs,oneIdxs,C(:,1),C(:,2),C(:,3),C(:,4),C(:,5),C(:,6),oneIdxs);
        resct(linIdxs) = resct(linIdxs) + int32( C(:,7).*mult' );
        [C,~,ic] = unique( [targetHasEnergy;nAct;curSnr;curSnr_avgSelf;azmErr;nEstErr;tn]', 'rows' );
        mult = arrayfun(@(x)(sum(x==ic)), 1:size(C,1));
        oneIdxs = ones(size(C(:,1)));
        linIdxs = sub2ind(size(resct),oneIdxs,oneIdxs,oneIdxs,oneIdxs,C(:,1),C(:,2),C(:,3),C(:,4),C(:,5),C(:,6),oneIdxs*2);
        resct(linIdxs) = resct(linIdxs) + int32( C(:,7).*mult' );
        [C,~,ic] = unique( [targetHasEnergy;nAct;curSnr;curSnr_avgSelf;azmErr;nEstErr;fp]', 'rows' );
        mult = arrayfun(@(x)(sum(x==ic)), 1:size(C,1));
        oneIdxs = ones(size(C(:,1)));
        linIdxs = sub2ind(size(resct),oneIdxs,oneIdxs,oneIdxs,oneIdxs,C(:,1),C(:,2),C(:,3),C(:,4),C(:,5),C(:,6),oneIdxs*3);
        resct(linIdxs) = resct(linIdxs) + int32( C(:,7).*mult' );
        [C,~,ic] = unique( [targetHasEnergy;nAct;curSnr;curSnr_avgSelf;azmErr;nEstErr;fn]', 'rows' );
        mult = arrayfun(@(x)(sum(x==ic)), 1:size(C,1));
        oneIdxs = ones(size(C(:,1)));
        linIdxs = sub2ind(size(resct),oneIdxs,oneIdxs,oneIdxs,oneIdxs,C(:,1),C(:,2),C(:,3),C(:,4),C(:,5),C(:,6),oneIdxs*4);
        resct(linIdxs) = resct(linIdxs) + int32( C(:,7).*mult' );
        clear aggrBAs;
        clear aggrCounts;
    end
end
fprintf( '\n' );

nActVsSnrAvgCounts2 = summarizeDown( resc(:,:,:,:,:,:,:,:,:,:,:), [6,8,11] );
nActVsSnrAvgBAC2 = 0.5*nActVsSnrAvgCounts2(:,:,1)./(nActVsSnrAvgCounts2(:,:,1)+nActVsSnrAvgCounts2(:,:,4)) + 0.5*nActVsSnrAvgCounts2(:,:,2)./(nActVsSnrAvgCounts2(:,:,2)+nActVsSnrAvgCounts2(:,:,3));

end

