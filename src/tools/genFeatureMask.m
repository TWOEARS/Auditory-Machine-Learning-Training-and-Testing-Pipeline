function [mask,featureDescription] = genFeatureMask( pipe, featuresToBeMasked )

if ~isa( pipe, 'TwoEarsIdTrainPipe' )
    error( 'Please provide a TwoEarsIdTrainPipe.' );
end

pipe.modelCreator = ModelTrainers.LoadModelNoopTrainer( 'noop' );
ksWrapperIdxAdd = double( ~isempty( pipe.ksWrapper ) );

pipe.setupSingleFileData( fullfile( getMFilePath(), 'void01.wav' ) );
sc = SceneConfig.SceneConfiguration();
sc.addSource( SceneConfig.DiffuseSource( 'data', SceneConfig.FileListValGen( 'pipeInput' ) ) );

pipe.init( sc, ...
           'gatherFeaturesProc', false, 'fs', 44100, 'loadBlockAnnotations', true, ...
           'stopAfterProc', 4+ksWrapperIdxAdd );
pipe.pipeline.run( 'modelPath', 'tmp_genFeatureMask', ...
                   'runOption', 'onlyGenCache', ...
                   'debug', true );

if pipe.pipeline.featureCreator.descriptionBuilt
    featureDescription = pipe.pipeline.featureCreator.description;
elseif ~isempty( pipe.pipeline.featureCreator.cacheSystemDir ) && exist( pipe.pipeline.featureCreator.lastFolder{1}, 'dir' )
    fdesc = load( fullfile( pipe.pipeline.featureCreator.lastFolder{1}, 'fdesc.mat' ) );
    featureDescription = fdesc.description;
else
    error( 'unexpected' );
end

mask = true( size( featureDescription ) );
for ii = 1 : numel( featuresToBeMasked )
    mask = mask & ~cellfun( @(c)(any( strcmpi( featuresToBeMasked{ii}, c) )), featureDescription );
end

end
