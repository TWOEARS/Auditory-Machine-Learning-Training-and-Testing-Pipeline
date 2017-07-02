function [agBAparamIdxs, asgn] = aggregateBlockAnnotations( blockAnnotations, yp, yt )

[bap, ~] = extractBAparams( blockAnnotations, yp, yt );

asgn{1} = any( yp > 0 ) && any( yt > 0 );
asgn{2} = all( yp < 0 ) && all( yt < 0 );
asgn{3} = any( yp > 0 ) && all( yt < 0 );
asgn{4} = all( yp < 0 ) && any( yt > 0 );

if asgn{1}
    idx = find( (yt > 0) );
elseif asgn{2}
    idx = 1 : numel( yt );
elseif asgn{3}
    idx = find( (yp > 0) & (yt < 0) );
elseif asgn{4}
    idx = find( (yp < 0) & (yt > 0) );
end

ag.azmErr = nanMean( bap.azmErr(idx) );
ag.nEstErr = nanMean( bap.nEstErr(idx) );
ag.nAct = nanMean( bap.nAct(idx) );
ag.targetHasEnergy = max( bap.targetHasEnergy(idx) );
ag.curSnr = nanMean( bap.curSnr(idx) );
ag.curSnr_avgSelf = nanMean( bap.curSnr_avgSelf(idx) );

agBAparamIdxs = baParams2bapIdxs( ag );

end