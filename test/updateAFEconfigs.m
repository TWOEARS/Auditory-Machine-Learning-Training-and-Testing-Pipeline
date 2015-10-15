function updateAFEconfigs()

classFolders = dir( [pwd filesep '*'] );
classFolders = classFolders([classFolders.isdir]);
classFolders(1:2) = [];

Parameters.dynPropsOnLoad( true, false );
for ii = 1 : length( classFolders )
    procFolders = dir( [pwd filesep classFolders(ii).name filesep 'AuditoryFEmodule.2*'] );
    procFolders = procFolders([procFolders.isdir]);
    fprintf('\n');
    for jj = 1 : length( procFolders )
        afeDir = [pwd filesep classFolders(ii).name filesep procFolders(jj).name];
        cfg = load( [afeDir filesep 'config.mat'] );
        if isfield( cfg.afeParams, 's' ) && isfield( cfg.afeParams, 'p' )
            continue;
        end
        if isfield( cfg, 'configHash' ) || isfield( cfg, 'reqSignals' )
            rmdir( afeDir, 's' );
            continue;
        end
        afeDatFiles = dir( [afeDir filesep '*.AuditoryFEmodule.mat'] );
        afeDat = load( [afeDir filesep afeDatFiles(1).name] );
        for kk = 1 : afeDat.afeData.Count
            afeParams.s(kk) = dataProcs.AuditoryFEmodule.signal2struct( ...
                afeDat.afeData(kk) );
        end
        afeParams.p = dataProcs.AuditoryFEmodule.parameterSummary2struct( ...
            cfg.afeParams );
        cfg.afeParams = afeParams;
        save( [afeDir filesep 'config.mat'], '-struct', 'cfg' );
        fprintf('.');
    end
end
Parameters.dynPropsOnLoad( true, true );
fprintf('\n');




