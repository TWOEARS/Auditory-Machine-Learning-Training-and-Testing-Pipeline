function boostedInterp_stats = interpSmoothStats( x_groups, y_groups, xq, nGroupBoosts, interpMethod, smoothingParams, firstElemMandatory, extrap )
% INTERPSMOOTHSTATS boosted 1-D interpolation, returning smoothed
% statistics. Boosting inside groups of data.
%
% x_groups: cell array of groups of x data. In each cell: 1-dim array.
% y_groups: cell array of groups of the respective y data. In each cell:
%               cell array of y samplings for the respective x. 
% xq: interpolation x 
% nGroupBoosts: array with boosting amount for each group. 
% interpMethod: interpolation method (cf. interp1 help)
% smoothingParams: cell array: {smoothing method (cf. smoothdata help),
%                               smoothing window}
% firstElemMandatory: boolean, whether the first element of each x_groups
%                     must be included, or can be included
% extrap: boolean, whether to extrapolate or not
%%
if nargin < 8 || isempty( extrap ), extrap = false; end

%%
femadd = double( ~firstElemMandatory );
yq = nan( 0, numel( xq ) );
for gg = 1 : numel( y_groups )
    y_gg = cellfun( @sort, y_groups{gg}, 'un', false );
    x_gg = x_groups{gg};
    if numel( y_gg ) == 1 && x_gg == 0
        continue;
    end
    y_gg_ySamplePtr = 0;
    y_gg_nYsamples = cellfun( @numel, y_gg );
    nSubsamples = max( ceil( (numel( y_gg )-1+femadd) / 3 ), min( 4, numel( x_gg )-1+femadd ) );
    subsampleIdxStepsize = ceil( (numel( y_gg )-1+femadd) / nSubsamples );
    subsampled_y_gg = nan( 1, nSubsamples+1-femadd );
    subsampled_x_gg = nan( 1, nSubsamples+1-femadd );
    if firstElemMandatory, subsampled_x_gg(1) = x_gg(1); end
    samplePrt_incr = 10 / nGroupBoosts(gg);
    samplePrt_rndPart = 2 ./ y_gg_nYsamples;
    for jj = 1 : nGroupBoosts(gg)
        y_gg_ySampleIdx = ceil( max( min( (y_gg_ySamplePtr + randn()*samplePrt_rndPart(1)), 1 ), 0+eps ) ...
                                           * y_gg_nYsamples(1) );
        if firstElemMandatory, subsampled_y_gg(1) = y_gg{1}(y_gg_ySampleIdx); end
        y_gg_ySamplePtr = y_gg_ySamplePtr + samplePrt_incr;
        if y_gg_ySamplePtr > 1
            y_gg_ySamplePtr = 0;
        end
        subsampleIdxs = subsampleIdxStepsize * (0 : nSubsamples - 1) ...
                        + 1 - femadd + randi( subsampleIdxStepsize, 1, nSubsamples );
        subsampleIdxs = unique( min( [subsampleIdxs; ...
                                      repmat( numel( y_gg ), 1, nSubsamples )], [], 1 ) );
        if numel( subsampleIdxs ) ~= nSubsamples
            subsampleIdxs = unique( [1, subsampleIdxs, subsampleIdxs(subsampleIdxs>1) - 1] );
            nTmp = numel( subsampleIdxs ) - 1 + femadd;
            subsampleIdxs(1-femadd+randperm( nTmp, nTmp - nSubsamples)) = [];
            if firstElemMandatory, subsampleIdxs(1) = []; end
        end
        subsampled_x_gg(2-femadd:end) = x_gg(subsampleIdxs);
        for ii = 1 : nSubsamples
            y_gg_ySampleIdx = ceil( max( min( (y_gg_ySamplePtr + randn()*samplePrt_rndPart(subsampleIdxs(ii))), 1 ), 0+eps ) ...
                                               * y_gg_nYsamples(subsampleIdxs(ii)) );
            subsampled_y_gg(ii+1-femadd) = y_gg{subsampleIdxs(ii)}(y_gg_ySampleIdx);
        end
        yq(end+1,:) = interp1( subsampled_x_gg, subsampled_y_gg, xq, interpMethod, nan );
        if extrap
            tmp = interp1( subsampled_x_gg, subsampled_y_gg, xq, 'nearest', 'extrap' );
            yq(end,isnan( yq(end,:) )) = tmp(isnan( yq(end,:) ));
        end
    end
end

boostedInterp_stats(1,:) = median( yq, 1, 'omitnan' );
boostedInterp_stats(2,:) = quantile( yq, 0.75, 1 );
boostedInterp_stats(3,:) = quantile( yq, 0.25, 1 );
sYq = sort( yq );
ncSyq = sum( ~isnan( sYq ), 1 );
ncSyq = max( ncSyq, ones( size( ncSyq ) ) );
nCoeff = 1.96*sqrt( ncSyq ) / 2;
indIdxs = sub2ind( size( sYq ), min( ncSyq, ceil( 1 + ncSyq/2 + nCoeff ) ),...
                                1 : size( sYq, 2 ) );
boostedInterp_stats(4,:) = sYq(indIdxs); % upper 95% confidence interval bound of the median
indIdxs = sub2ind( size( sYq ), max( ones( size( ncSyq ) ), floor( ncSyq/2 - nCoeff ) ), ...
                                1 : size( sYq, 2 ) );
boostedInterp_stats(5,:) = sYq(indIdxs); % lower 95% confidence interval bound of the median
% https://www.ucl.ac.uk/child-health/short-courses-events/about-statistical-courses/statistics-and-research-methods/chapter-8-content-2
boostedInterp_stats(6,:) = nanMean( yq, 1 );
bisIsNan = isnan( boostedInterp_stats );
smoothed_stats = smoothdata( boostedInterp_stats, 2, smoothingParams{:} );
if firstElemMandatory
    fes = mean( cellfun( @(c)(c(1)), x_groups ) );
    [~,fesidx] = min( abs( xq - fes ) );
    fesw = 3;
    fesidxs = fesidx-fesw:fesidx+fesw;
    bisr = [0:1/fesw:1,1-1/fesw:-1/fesw:0];
    bisr(fesidxs<1 | fesidxs>size(smoothed_stats,2)) = [];
    ssr = 1 - bisr;
    fesidxs(fesidxs<1 | fesidxs>size(smoothed_stats,2)) = [];
    smoothed_stats(:,fesidxs) = repmat( bisr, 6, 1 ) .* boostedInterp_stats(:,fesidxs) ...
                                + repmat( ssr, 6, 1 ) .* smoothed_stats(:,fesidxs);
end
boostedInterp_stats = smoothed_stats;
boostedInterp_stats(bisIsNan) = nan;

end