function maintainAllCaches( idPipeCacheDir )

ipcDirs = dir( idPipeCacheDir );
parfor jj = 1 : numel( ipcDirs )

    if ~ipcDirs(jj).isdir, continue; end
    if ipcDirs(jj).name(1) == '.', continue; end
    afeCacheDir = [idPipeCacheDir filesep ipcDirs(jj).name];
    if all( arrayfun( @(a)(a.name(1)), dir( afeCacheDir ) ) == '.' ), continue; end
    fprintf( '\n%s\n', afeCacheDir );
    
    movefile( [afeCacheDir filesep 'cacheDirectory.mat'], [afeCacheDir filesep 'cacheDirectory.mat.bak'] );
    Core.IdCacheDirectory.standaloneMaintain( afeCacheDir );

end
