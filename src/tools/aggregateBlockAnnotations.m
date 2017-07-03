function [agBAparamIdxs, asgn] = aggregateBlockAnnotations( bap, yp, yt )

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

ag.azmErr = nanMean( [bap(idx).azmErr] );
ag.nEstErr = nanMean( [bap(idx).nEstErr] );
ag.nAct = nanMean( [bap(idx).nAct] );
ag.targetHasEnergy = max( [bap(idx).targetHasEnergy] );
ag.curSnr = nanMean( [bap(idx).curSnr] );
ag.curSnr_avgSelf = nanMean( [bap(idx).curSnr_avgSelf] );

agBAparamIdxs = baParams2bapIdxs( ag );

end