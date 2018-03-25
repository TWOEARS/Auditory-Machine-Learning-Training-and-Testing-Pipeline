function maintainAllCaches( idPipeCacheDir, chooseDirs, parM )

if nargin < 2 || isempty( chooseDirs ), chooseDirs = false; end
if nargin < 3 || isempty( parM ), parM = 12; end

ipcDirs = dir( idPipeCacheDir );

if chooseDirs
    for jj = numel( ipcDirs ):-1:1

        if ~ipcDirs(jj).isdir
            ipcDirs(jj) = []; 
            continue;
        end
        if ipcDirs(jj).name(1) == '.'
            ipcDirs(jj) = []; 
            continue;
        end
        cacheDir_jj = [idPipeCacheDir filesep ipcDirs(jj).name];
        if all( arrayfun( @(a)(a.name(1)), dir( cacheDir_jj ) ) == '.' )
            ipcDirs(jj) = []; 
            continue;
        end
        
        choice = input( sprintf( 'Maintain %s? [y/n]', ipcDirs(jj).name ), 's' );
        if choice == 'n'
            ipcDirs(jj) = [];
            continue;
        end
    end
end

parfor (jj = 1 : numel( ipcDirs ), parM)

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
