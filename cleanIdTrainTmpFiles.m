function cleanIdTrainTmpFiles( )

fprintf( ['\nCleaning Training Pipeline Temporary Files Tool\n' ...
          '===============================================\n'] );

while true
    currentDir = pwd;
    fprintf( '\nWe''re in %s.\n\n', currentDir );
    fprintf( 'Looking for tmp proc folders...\nFound:\n' );
    
    procFoldersDir = dir( [currentDir filesep '*.*'] );
    procFoldersDir(1:2) = []; % "." and ".."
    procFoldersDir([procFoldersDir.isdir] == 0) = [];
    ii = 1;
    while ii <= length( procFoldersDir )
        if exist( [procFoldersDir(ii).name filesep 'config.mat'], 'file' )
            ii = ii + 1;
        else
            procFoldersDir(ii) = [];
        end
    end
    
    procList = listProcFolders( procFoldersDir );

    choice = [];
    while isempty( choice )
        choice = input( ['\n''q'' to quit. ' ...
                         '''l'' nr to look, '...
                         '''d'' nr to delete.'...
                         'nr can be a range as in 10-50. >> '], 's' );
    end
    
    if strcmpi( choice, 'q' )
        break;
    else
        [cmd,arg] = strtok( choice, ' ' );
        listNames = keys(procList);
        [arg1,arg2] = strtok( arg, '-' );
        if isempty( arg2 ), arg2 = arg1; end
        arg = str2double( arg1 ) : str2double( arg2(2:end) );
        idxs = [];
        for ii = 1 : numel( arg )
            idxs = [idxs procList(listNames{arg(ii)})];
        end
        if strcmpi( cmd, 'l' )
            for ii = idxs
                presentProcFolder( procFoldersDir(ii).name );
                input( 'press enter to continue', 's' );
            end
        elseif strcmpi( cmd, 'd' )
            for ii = idxs
                fprintf( 'Deleting %s...\n', procFoldersDir(ii).name );
                rmdir( procFoldersDir(ii).name, 's' );
            end
        end
    end
end

end

% ---------------------------------------------------------------------------------------%

function procList = listProcFolders( procFolders )

choice = input( 'Enter to see all folders, ''t'' to see by type, ''c'' by content >> ', 's' );
procList = containers.Map('KeyType','char','ValueType','any');
if isempty( choice )
    for ii = 1 : length( procFolders )
        procList(procFolders(ii).name) = ii;
    end
elseif strcmpi( choice, 't' )
    for ii = 1 : length( procFolders )
        procName = strtok( procFolders(ii).name, '.' );
        if ~procList.isKey( procName )
            procList(procName) = ii;
        else
            procList(procName) =  [procList(procName), ii];
        end
    end
elseif strcmpi( choice, 'c' )
end
procNames = keys( procList );
for ii = 1 : length( procNames )
    fprintf( '%i: \t%s\n', ii, procNames{ii} );
end


end

% ---------------------------------------------------------------------------------------%

function presentProcFolder( procFolder )

cprintf( '-Blue', '\n.:%s:.\n', procFolder );
config = load( [procFolder filesep 'config.mat'] );
flatPrintObject( config, 10 );

end

% ---------------------------------------------------------------------------------------%

