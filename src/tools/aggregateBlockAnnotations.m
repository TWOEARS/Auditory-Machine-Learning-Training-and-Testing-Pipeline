function [ag, asgn] = aggregateBlockAnnotations( bap, yp, yt )

[ytIdxR,ytIdxC] = find( yt > 0 );
assert( numel( unique( ytIdxR ) ) == numel( ytIdxR ) ); % because I defined it in my test scripts: target sounds only on src1
isyt = false( size( bap, 1 ), 1 );
isyt(ytIdxR) = true;
isyp = any( yp > 0, 2 );

asgn(:,1) = isyp & isyt;
asgn(:,2) = ~isyp & ~isyt;
asgn(:,3) = isyp & ~isyt;
asgn(:,4) = ~isyp & isyt;

ag = bap(:,1);
[ag.nAct_segStream] = deal( nan );

tmp = reshape( [bap.distToClosestSrc], size( bap ) );
tmp = num2cell( nanMean( tmp, 2 ) );
[ag.distToClosestSrc] = tmp{:};

tmp = reshape( [bap.multiSrcsAttributability], size( bap ) );
tmp = num2cell( nanMean( tmp, 2 ) );
[ag.multiSrcsAttributability] = tmp{:};

ytIdxs = sub2ind( size( yt ), ytIdxR, ytIdxC );
[ag(isyt).curSnr] = bap(ytIdxs).curSnr;
[ag(isyt).curNrj] = bap(ytIdxs).curNrj;
[ag(isyt).curNrjOthers] = bap(ytIdxs).curNrjOthers;
[ag(isyt).azmErr] = bap(ytIdxs).azmErr;

tmp = reshape( double( [bap(~isyt,:).curSnr] ), size( bap(~isyt,:) ) );
[~,maxCurSnrIdx] = max( tmp, [], 2 );

nIdxs = sub2ind( size( yt ), find( ~isyt ), maxCurSnrIdx );
[ag(~isyt).curSnr] = bap(nIdxs).curSnr;
[ag(~isyt).curNrj] = bap(nIdxs).curNrj;
[ag(~isyt).curNrjOthers] = bap(nIdxs).curNrjOthers;
[ag(~isyt).azmErr] = deal( nan );

end

function v = nanIfEmpty( v )
if isempty( v )
    v = nan;
end
end