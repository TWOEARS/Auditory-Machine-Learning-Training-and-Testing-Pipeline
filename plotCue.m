function plotCue( cueData, cueName  )

figure;
if size( size(cueData),2 ) == 2
    imagesc( cueData )
else
    plot( cueData );
end
title( cueName )
