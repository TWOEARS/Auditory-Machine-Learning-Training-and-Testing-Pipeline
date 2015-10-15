function updateFeatureConfigs()

fs1bmAfeP = load( 'fs1bm.mat' );
fs1bm2AfeP = load( 'fs1bm.mat' );
fs1bmlhAfeP = load( 'fs1bmlh.mat' );
fs1bmvarAfeP = load( 'fs1bmlh.mat' );

classFolders = dir( [pwd filesep '*'] );
classFolders = classFolders([classFolders.isdir]);
classFolders(1:2) = [];

Parameters.dynPropsOnLoad( true, false );
for ii = 1 : length( classFolders )
    updateFeatureSet( 'FeatureSet1Blockmean', 1082, fs1bmAfeP );
    updateFeatureSet( 'FeatureSet1Blockmean2Ch', 2164, fs1bm2AfeP );
    updateFeatureSet( 'FeatureSet1VarBlocks', 2982, fs1bmvarAfeP );
    updateFeatureSet( 'FeatureSet1BlockmeanLowVsHighFreqRes', 4020, fs1bmlhAfeP );
end
Parameters.dynPropsOnLoad( true, true );
fprintf('\n');



function updateFeatureSet( fsetName, reqDim, fsetP )
    procFolders = dir( [pwd filesep classFolders(ii).name filesep fsetName '.2*'] );
    procFolders = procFolders([procFolders.isdir]);
    fprintf('\n');
    for jj = 1 : length( procFolders )
        featDir = [pwd filesep classFolders(ii).name filesep procFolders(jj).name];
        cfg = load( [featDir filesep 'config.mat'] );
        if isfield( cfg, 'configHash' ) || isfield( cfg, 'reqSignals' )
            rmdir( featDir, 's' );
            continue;
        end
        featDatFiles = dir( [featDir filesep '*.' fsetName '.mat'] );
        featDat = load( [featDir filesep featDatFiles(1).name] );
        if size( featDat.x, 2 ) ~= reqDim
            rmdir( featDir, 's' );
            continue;
        end
        cfg.extern.afeParams = fsetP.afeParams;
        clear afeParams;
        save( [featDir filesep 'config.mat'], '-struct', 'cfg' );
        fprintf('.');
    end
end

end