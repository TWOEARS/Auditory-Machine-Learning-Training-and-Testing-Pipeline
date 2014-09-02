function eventClass = readEventClass( soundFileName )

fileSepPositions = strfind( soundFileName, filesep );

if isempty( fileSepPositions )
    error( 'Cannot infer sound event class - possibly because "%d" is not a full path.', soundFileName );
end

classPos1 = fileSepPositions(end-1);
classPos2 = fileSepPositions(end);

eventClass = soundFileName(classPos1+1:classPos2-1);