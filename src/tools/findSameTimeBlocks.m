function [blockAnnotations,yt,yp,sameTimeIdxs] = findSameTimeBlocks( blockAnnotations,yt,yp )

[~,~,sameTimeIdxs] = unique( [blockAnnotations.blockOffset] );
for bb = 1 : max( sameTimeIdxs )
    [blockAnnotations(sameTimeIdxs==bb).allGtAzms] = deal( [blockAnnotations(sameTimeIdxs==bb).srcAzms] );
end

end

