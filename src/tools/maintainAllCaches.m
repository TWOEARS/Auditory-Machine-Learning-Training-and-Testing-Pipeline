function maintainAllCaches( idPipeCacheDir )

ipcDirs = dir( idPipeCacheDir );
parfor (jj = 1 : numel( ipcDirs ), 6)

    if ~ipcDirs(jj).isdir, continue; end
    if ipcDirs(jj).name(1) == '.', continue; end
    cacheDir_jj = [idPipeCacheDir filesep ipcDirs(jj).name];
    if all( arrayfun( @(a)(a.name(1)), dir( cacheDir_jj ) ) == '.' ), continue; end
    fprintf( '\n%s\n', cacheDir_jj );
    
    if exist( [cacheDir_jj filesep 'cacheDirectory.mat'], 'file' )
        movefile( [cacheDir_jj filesep 'cacheDirectory.mat'], [cacheDir_jj filesep 'cacheDirectory.mat.bak' buildCurrentTimeString()] );
    end
    Core.IdCacheDirectory.standaloneMaintain( cacheDir_jj );

end
