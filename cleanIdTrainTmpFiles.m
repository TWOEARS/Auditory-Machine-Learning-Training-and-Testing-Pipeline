function cleanIdTrainTmpFiles( )

fprintf( ['\nCleaning Training Pipeline Temporary Files Tool\n' ...
          '===============================================\n'] );

while true
    currentDir = pwd;
    fprintf( '\nWe''re in %s.\n\n', currentDir );
    fprintf( 'Looking for tmp proc folders...\nFound:\n' );
    
    classFoldersDir = dir( [currentDir filesep '*'] );
    classFoldersDir(1:2) = []; % "." and ".."
    classFoldersDir([classFoldersDir.isdir] == 0) = [];
    procFoldersDir = [];
    for jj = 1 : length( classFoldersDir )
        classProcFoldersDir = dir( [currentDir filesep classFoldersDir(jj).name filesep '*.*'] );
        classProcFoldersDir(1:2) = []; % "." and ".."
        classProcFoldersDir([classProcFoldersDir.isdir] == 0) = [];
        [classProcFoldersDir(:).class] = deal( classFoldersDir(jj).name );
        procFoldersDir = [procFoldersDir; classProcFoldersDir];
    end
    ii = 1;
    while ii <= length( procFoldersDir )
        if exist( [procFoldersDir(ii).class filesep procFoldersDir(ii).name filesep 'config.mat'], 'file' )
            ii = ii + 1;
        else
            procFoldersDir(ii) = [];
        end
    end
    
    procList = listProcFolders( procFoldersDir );

    choice = [];
        choice = input( ['\n''q'' to quit. ' ...
                         'Enter to go back, '...
                         '''l'' nr to look, '...
                         '''d'' nr to delete. '...
                         'nr can be a range as in 10-50. >> '], 's' );
    
    if strcmpi( choice, 'q' )
        break;
    elseif ~isempty( choice )
        [cmd,arg] = strtok( choice, ' ' );
        listNames = keys(procList);
        [arg1,arg2] = strtok( arg, '-' );
        if isempty( arg2 ), arg2 = arg1; end
        arg = str2double( arg1 ) : str2double( arg2(2:end) );
        idxs = [];
        for ii = 1 : numel( arg )
            idxs = [idxs getMapStructElem( procList, listNames{arg(ii)}, 'idxs' )];
        end
        if strcmpi( cmd, 'l' )
            for ii = idxs
                presentProcFolder( [procFoldersDir(ii).class filesep procFoldersDir(ii).name] );
                input( 'press enter to continue', 's' );
            end
        elseif strcmpi( cmd, 'd' )
            for ii = idxs
                fprintf( 'Deleting %s...\n', [procFoldersDir(ii).class filesep procFoldersDir(ii).name] );
                rmdir( [procFoldersDir(ii).class filesep procFoldersDir(ii).name], 's' );
            end
        end
    end
end

end

% ---------------------------------------------------------------------------------------%

function procList = listProcFolders( procFolders )

choice = input( 'Enter to see all folders, ''t'' to see by type, ''c'' by config >> ', 's' );
procList = containers.Map('KeyType','char','ValueType','any');
if isempty( choice )
    for ii = 1 : length( procFolders )
        assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'idxs', ii );
    end
elseif strcmpi( choice, 't' )
    for ii = 1 : length( procFolders )
        procName = strtok( procFolders(ii).name, '.' );
        if ~procList.isKey( procName )
            assignMapStructElem( procList, procName, 'idxs', ii );
        else
            assignMapStructElem( procList, procName, 'idxs', ...
                [getMapStructElem( procList, procName, 'idxs' ) ii] );
        end
    end
elseif strcmpi( choice, 'c' )
    for ii = 1 : length( procFolders )
        iiConfig = load( [procFolders(ii).class filesep procFolders(ii).name filesep 'config.mat'] );
        if isempty( procList )
            assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'idxs', ii );
            assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'config', iiConfig );
        else
            procNames = keys( procList );
            configFound = false;
            for jj = 1 : length( procNames )
                if isequalDeepCompare( getMapStructElem( procList, procNames{jj}, 'config' ), iiConfig )
                    assignMapStructElem( procList, procNames{jj}, 'idxs',...
                        [getMapStructElem( procList, procNames{jj}, 'idxs' ), ii] );
                    configFound = true;
                    break;
                end
            end
            if ~configFound
                assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'idxs', ii );
                assignMapStructElem( procList, [procFolders(ii).class filesep procFolders(ii).name], 'config', iiConfig );
            end
        end
    end
end
procNames = keys( procList );
for ii = 1 : length( procNames )
    fprintf( '%i: \t%s \t(%i folders)\n', ...
        ii, procNames{ii}, numel( getMapStructElem( procList, procNames{ii}, 'idxs' ) ) );
end


end

% ---------------------------------------------------------------------------------------%

function presentProcFolder( procFolder )

cprintf( '-Blue', '\n.:%s:.\n', procFolder );
config = load( [procFolder filesep 'config.mat'] );
flatPrintObject( config, 10 );

end

% ---------------------------------------------------------------------------------------%

function assignMapStructElem( map, key, fieldname, val )

if map.isKey( key )
    s = map(key);
end
s.(fieldname) = val;
map(key) = s;

end

function val = getMapStructElem( map, key, fieldname  )

s = map(key);
val = s.(fieldname);

end

% ---------------------------------------------------------------------------------------%

