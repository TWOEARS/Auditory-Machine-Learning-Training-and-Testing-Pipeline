function [ag, asgn] = aggregateBlockAnnotations( bap, yp, yt, extraFields )

ytIdx = find( yt > 0 );
assert( numel( ytIdx ) <= 1 ); % because I defined it in my test scripts: target sounds only on src1
isyt = ~isempty( ytIdx );
isyp = any( yp > 0 );

asgn(1,1) = isyp && isyt;
asgn(1,2) = ~isyp && ~isyt;
asgn(1,3) = isyp && ~isyt;
asgn(1,4) = ~isyp && isyt;

for ii = 1 : numel( extraFields )
    ag.(extraFields{ii}) = bap(1).(extraFields{ii});
end
ag.nAct = bap(1).nAct;
ag.nEstErr = bap(1).nEstErr;
ag.scpId = bap(1).scpId;
ag.whiteNoise = bap(1).whiteNoise;
ag.headPosIdx = bap(1).headPosIdx;
ag.nAct_segStream = nan;
ag.distToClosestSrc = nanMean( [bap.distToClosestSrc] );
ag.multiSrcsAttributability = nanMean( [bap.multiSrcsAttributability] );
if isyt
    ag.curSnr = bap(ytIdx).curSnr;
    ag.curNrj = bap(ytIdx).curNrj;
    ag.curNrjOthers = bap(ytIdx).curNrjOthers;
    ag.azmErr = bap(ytIdx).azmErr;
else
    curSnr = [bap.curSnr];
    [~,maxCurSnrIdx] = max( curSnr );
    ag.curSnr = curSnr(maxCurSnrIdx);
    ag.curNrj = bap(maxCurSnrIdx).curNrj;
    ag.curNrjOthers = bap(maxCurSnrIdx).curNrjOthers;
    ag.azmErr = nan;
end

end