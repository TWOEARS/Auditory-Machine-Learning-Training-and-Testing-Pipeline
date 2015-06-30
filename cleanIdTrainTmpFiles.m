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
            fprintf( '%i: \t%s\n', ii, procFoldersDir(ii).name );
            ii = ii + 1;
        else
            procFoldersDir(ii) = [];
        end
    end
    
    choice = input( ['\n''stfu'' to quit. Enter to look through all,' ...
        'or choose the according number and then press enter. >>'] );
    
    if ischar( choice ) && strcmpi( choice, 'q' )
        break;
    elseif isempty( choice ) % direct enter
        for ii = 1 : length( procFoldersDir )
            presentProcFolder( procFoldersDir(ii).name );
        end
    else
        presentProcFolder( procFoldersDir(choice).name );
    end
end

end

% ---------------------------------------------------------------------------------------%

function presentProcFolder( procFolder )

cprintf( '-Blue', '\n.:%s:.\n', procFolder );
config = load( [procFolder filesep 'config.mat'] );
flatPrintObject( config );
choice = input( 'Enter to do nothing, ''d'' to delete this tmp proc folder. >>', 's' );
if ~isempty( choice ) && strcmpi( choice, 'd' )
    fprintf( 'Deleting %s...\n', procFolder );
    rmdir( procFolder, 's' );
end

end

% ---------------------------------------------------------------------------------------%

function choice = stfu()

choice = 'q';

end

% ---------------------------------------------------------------------------------------%
