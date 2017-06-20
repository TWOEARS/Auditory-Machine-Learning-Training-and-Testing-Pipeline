function [aggrBA, aggrCounts] = aggregateBlockAnnotations( blockAnnotations, counts )

aggrCounts.tp = any( [counts.yp] > 0 ) && any( [counts.yt] > 0 );
aggrCounts.tn = all( [counts.yp] < 0 ) && all( [counts.yt] < 0 );
aggrCounts.fp = any( [counts.yp] > 0 ) && all( [counts.yt] < 0 );
aggrCounts.fn = all( [counts.yp] < 0 ) && any( [counts.yt] > 0 );

estAzms = [blockAnnotations.estAzm];
gtAzms = cellfun( @(x)([x nan]), {blockAnnotations.srcAzms}, 'UniformOutput', false );
azmErrTpFn = abs( wrapTo180( cellfun( @(x)(x(1)), gtAzms ) - estAzms ) );
azmErrTnFp = abs( wrapTo180( cellfun( @(x)(nanMean(x)), gtAzms ) - estAzms ) );
azmErr = ([counts.yt] > 0) .* azmErrTpFn + ([counts.yt] < 0) .* azmErrTnFp;
        
nEstErr = [blockAnnotations.nSrcs_estimationError];
nAct = [blockAnnotations.nSrcs_active];

curNrj = cellfun( @(x)(max([x{:} single(-inf)])), {blockAnnotations.srcEnergy}, 'UniformOutput', false );
targetHasEnergy = cellfun( @(x)(x > -40), curNrj, 'UniformOutput', true );
curSnr = cellfun( @(x)([x{:} nan]), {blockAnnotations.srcSNR}, 'UniformOutput', false );
curSnrTpFn = max( cellfun( @(x)(single( x(1) )), curSnr ), -40 );
curSnrTnFp = max( cellfun( @(x)(nanMean(single( x ))), curSnr ), -40 );
curSnrTpFn(cellfun( @(x)(isnan(x(1))), curSnr )) = single( nan );
curSnrTnFp(cellfun( @(x)(isnan(x(1))), curSnr )) = single( nan );
curSnr = ([counts.yt] > 0) .* curSnrTpFn + ([counts.yt] < 0) .* curSnrTnFp;
curSnr_avgSelf = cellfun( @(x)([x{:} nan]), {blockAnnotations.srcSNR_avgSelf}, 'UniformOutput', false );
curSnr_avgSelfTpFn = max( cellfun( @(x)(single( x(1) )), curSnr_avgSelf ), -40 );
curSnr_avgSelfTnFp = max( cellfun( @(x)(nanMean(single( x ))), curSnr_avgSelf ), -40 );
curSnr_avgSelfTpFn(cellfun( @(x)(isnan(x(1))), curSnr_avgSelf )) = single( nan );
curSnr_avgSelfTnFp(cellfun( @(x)(isnan(x(1))), curSnr_avgSelf )) = single( nan );
curSnr_avgSelf = ([counts.yt] > 0) .* curSnr_avgSelfTpFn + ([counts.yt] < 0) .* curSnr_avgSelfTnFp;

if aggrCounts.tp
    idx = find( ([counts.yp] > 0) & ([counts.yt] > 0) );
elseif aggrCounts.tn
    idx = find( ([counts.yp] < 0) & ([counts.yt] < 0) );
elseif aggrCounts.fp
    idx = find( ([counts.yp] > 0) & ([counts.yt] < 0) );
elseif aggrCounts.fn
    idx = find( ([counts.yp] < 0) & ([counts.yt] > 0) );
end

aggrBA.azmErr = nanMean( azmErr(idx) );
aggrBA.nEstErr = nanMean( nEstErr(idx) );
aggrBA.nAct = nanMean( nAct(idx) );
aggrBA.targetHasEnergy = max( targetHasEnergy(idx) );
aggrBA.curSnr = nanMean( curSnr(idx) );
aggrBA.curSnr_avgSelf = nanMean( curSnr_avgSelf(idx) );

aggrBA.azmErr = round( aggrBA.azmErr/3 ) + 2;
aggrBA.azmErr(isnan(aggrBA.azmErr)) = 1;
aggrBA.azmErr(isinf(aggrBA.azmErr)) = 1;

aggrBA.nEstErr = aggrBA.nEstErr + 4;
aggrBA.nAct = aggrBA.nAct + 1;

aggrBA.targetHasEnergy = aggrBA.targetHasEnergy + 1;
aggrBA.curSnr = round( aggrBA.curSnr/5 ) + 10;
aggrBA.curSnr(isinf(aggrBA.curSnr)) = 1;
aggrBA.curSnr(isnan(aggrBA.curSnr)) = 1;
aggrBA.curSnr_avgSelf = round( aggrBA.curSnr_avgSelf/5 ) + 10;
aggrBA.curSnr_avgSelf(isinf(aggrBA.curSnr_avgSelf)) = 1;
aggrBA.curSnr_avgSelf(isnan(aggrBA.curSnr_avgSelf)) = 1;

end