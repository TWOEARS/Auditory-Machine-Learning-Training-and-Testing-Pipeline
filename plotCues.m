function plotCues( cues )

for ii = 1 : length(cues)
    lrStrPosition = strfind( cues(ii).dim, 'left right' );
    if isempty( lrStrPosition{1} )
      plotCue( cues(ii).data, cues(ii).name );
    else
      plotCue( extractChannel( cues(ii).data, 1 ), [cues(ii).name ' left'] );
      plotCue( extractChannel( cues(ii).data, 2 ), [cues(ii).name ' right'] );
    end
end

end

        