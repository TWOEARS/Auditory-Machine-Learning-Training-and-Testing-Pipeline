function [ag, asgn] = aggregateBlockAnnotations( bap, yp, yt )

isyt = yt > 0;
isyp = yp > 0;
[ytIdxR,ytIdxC] = find( isyt );
assert( numel( unique( ytIdxR ) ) == numel( ytIdxR ) ); % because I defined it in my test scripts: target sounds only on src1
isytR = any( isyt, 2 );
isypR = any( isyp, 2 );
ist2tpR = isytR & isypR;

asgn{1} = ist2tpR;
asgn{2} = ~isypR & ~isytR;
asgn{3} = isypR & ~isytR;
asgn{4} = ~isypR & isytR;

ag = bap(:,1);
% [ag.nAct_segStream] = deal( nan );


if any( isytR )
ytIdxs = sub2ind( size( yt ), ytIdxR, ytIdxC );
% [ag(isytR).curSnr] = bap(ytIdxs).curSnr;
% [ag(isytR).curNrj] = bap(ytIdxs).curNrj;
% [ag(isytR).curNrjOthers] = bap(ytIdxs).curNrjOthers;
% [ag(isytR).curSnr_db] = bap(ytIdxs).curSnr_db;
% [ag(isytR).curNrj_db] = bap(ytIdxs).curNrj_db;
% [ag(isytR).curNrjOthers_db] = bap(ytIdxs).curNrjOthers_db;
[ag(isytR).curSnr2] = bap(ytIdxs).curSnr2;
% [ag(isytR).dist2bisector] = bap(ytIdxs).dist2bisector;
[ag(isytR).blockClass] = bap(ytIdxs).blockClass;
[ag(isytR).gtAzm] = bap(ytIdxs).gtAzm;
[ag(isytR).azmErr] = bap(ytIdxs).azmErr;
if any( ist2tpR )
    tp_gtAzms = [ag(ist2tpR).gtAzm];
    assert( all( ~isnan( tp_gtAzms ) ) );
    tpEstAzms = arrayfun( @(x)(x.estAzm), bap(ist2tpR,:) );
    azmErrs = tpEstAzms - repmat( tp_gtAzms', 1, size( bap, 2 ) );
    azmErrs = abs( wrapTo180( azmErrs ) );
    azmErrs(~isyp(ist2tpR,:)) = nan;
    tpAzmErrs = num2cell( nanMean( azmErrs, 2 ) );
    [ag(ist2tpR).azmErr] = tpAzmErrs{:};
end
end

if any( ~isytR )
% tmp = reshape( double( [bap(~isytR,:).curSnr2] ), size( bap(~isytR,:) ) );
% [~,maxCurSnrIdx] = max( tmp, [], 2 );
% nIdxs = sub2ind( size( yt ), find( ~isytR ), maxCurSnrIdx );
% [ag(~isytR).curSnr] = bap(nIdxs).curSnr;
% [ag(~isytR).curNrj] = bap(nIdxs).curNrj;
% [ag(~isytR).curNrjOthers] = bap(nIdxs).curNrjOthers;
% [ag(~isytR).dist2bisector] = bap(nIdxs).dist2bisector;
[ag(~isytR).blockClass] = deal( nan );
[ag(~isytR).gtAzm] = deal( nan );
% tmp = reshape( double( [bap(~isytR,:).curSnr_db] ), size( bap(~isytR,:) ) );
% [~,maxCurSnrIdx] = max( tmp, [], 2 );
% nIdxs = sub2ind( size( yt ), find( ~isytR ), maxCurSnrIdx );
% [ag(~isytR).curSnr_db] = bap(nIdxs).curSnr_db;
% [ag(~isytR).curNrj_db] = bap(nIdxs).curNrj_db;
% [ag(~isytR).curNrjOthers_db] = bap(nIdxs).curNrjOthers_db;
% tmp = reshape( double( [bap(~isytR,:).curSnr2] ), size( bap(~isytR,:) ) );
% [~,maxCurSnrIdx] = max( tmp, [], 2 );
% nIdxs = sub2ind( size( yt ), find( ~isytR ), maxCurSnrIdx );
[ag(~isytR).curSnr2] = deal( nan );
[ag(~isytR).azmErr] = deal( nan );
[ag(~isytR).nYp] = deal( 0 );
end

azmErrs = arrayfun( @(x)(x.azmErr), bap );
azmErrs2 = nanMean( azmErrs, 2 );
azmErrs3 = nanStd( azmErrs, 2 );
tmp = num2cell( azmErrs2 );
[ag(:).azmErr2] = tmp{:};
tmp = num2cell( azmErrs3 );
[ag(:).azmErr3] = tmp{:};
tmp = num2cell( sum( yp > 0, 2 ) );
[ag(:).nYp] = tmp{:};
[ag(:).estAzm] = deal( nan );

end
