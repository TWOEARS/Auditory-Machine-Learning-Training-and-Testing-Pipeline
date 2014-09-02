function onsetOffset = readOnOffAnnotations( soundFileName )

annotFid = fopen( [soundFileName '.txt'] );
if annotFid ~= -1
    onsetOffset = [];
    while 1
        annotLine = fgetl( annotFid );
        if ~ischar( annotLine ), break, end
        onsetOffset(end+1,:) = sscanf( annotLine, '%f' );
    end
else
    warning( sprintf( 'label annotation file not found: %s. Assuming no events.', soundFileName ) );
    onsetOffset = [ inf, inf ];
end
