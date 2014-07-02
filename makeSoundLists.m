function [classSoundFileNames, soundFileNames, classNames] = makeSoundLists( soundsDir, className )

% find all sound files in class dir
classDir = [soundsDir '/' className];
classSoundFileNames = dir( [classDir '/*.wav'] );
classSoundFileNames = {classSoundFileNames(:).name}';
classSoundFileNames = strcat( [classDir '/'], classSoundFileNames );

classNames = [];
% find all sound files in other class dirs
soundDirNames = dir( soundsDir );
for i = 1: size( soundDirNames, 1 )
    if strcmpi( soundDirNames(i).name, '.' ) == 1; continue; end;
    if strcmpi( soundDirNames(i).name, '..' ) == 1; continue; end;
    if soundDirNames(i).isdir ~= 1; continue; end;
    soundDirTmp = [soundsDir '/' soundDirNames(i).name '/'];
    soundFileNamesTmp = dir( [soundDirTmp '*.wav'] ); 
    soundFileNamesTmp = {soundFileNamesTmp(:).name}';
    soundFileNamesTmp = strcat( soundDirTmp, soundFileNamesTmp );
    if ~exist( 'soundFileNames', 'var' ); soundFileNames = soundFileNamesTmp; 
    else soundFileNames = [soundFileNames ; soundFileNamesTmp]; end;
    classNames = [classNames; repmat( {soundDirNames(i).name, i}, size( soundFileNamesTmp, 1 ), 1 )];
end
