function polarplot_scenes( ascp, iis, compress_iis )

if nargin < 2 || isempty( iis )
    iis = 1:numel( ascp );
end
if nargin < 3 || isempty( compress_iis )
    compress_iis = false;
end

figure;

rr = 1.1;
rr_azms = ones(numel( ascp ), 360);

for ii = iis
    sazms = sort( wrapTo360( ascp(ii).azms + 360 ) );
    neighboursAzmD = abs( wrapTo360( [sazms(2:end) sazms(1)] - sazms + 360 ) );
    [~,maxAzmDidx] = max( neighboursAzmD );
    firstSrcIdx = mod( maxAzmDidx, numel( sazms ) ) + 1;
    plotazms = sazms(firstSrcIdx);
    rrazmsquant = round( sazms(firstSrcIdx) );
    for jj = wrapTo360( [sazms(firstSrcIdx+1:end), sazms(1:firstSrcIdx-1)] )
        if jj < plotazms(end)
            jj = jj + 360;
        end
        plotazms = [plotazms plotazms(end):1:jj];
        rrazmsquant = [rrazmsquant rrazmsquant(end):1:round(jj)];
    end
    if ~compress_iis
        rr = rr + 0.1;
    else
        minfreerr = find( all( rr_azms(:,wrapTo1_360(rrazmsquant)), 2 ), 1 );
        rr_azms(minfreerr,wrapTo1_360(rrazmsquant)) = 0;
        rr = minfreerr * 0.1 + 1.1;
%         rr_azms(wrapTo1_360(rrazmsquant)) = max( rr_azms(wrapTo1_360(rrazmsquant)) ) + 0.1;
%         rr = rr_azms(wrapTo1_360(rrazmsquant(1)));
    end
    pph = polarplot( deg2rad( plotazms ), repmat( rr, size( plotazms ) ), '-', 'LineWidth', 0.5, 'color', [0.3,0.3,0.3] );
    pphColor = get( pph, 'Color' );
    hold on
    polarscatter( deg2rad( sazms ), repmat( rr, size( sazms ) ), 'filled', 'MarkerFaceColor', pphColor );
    polarscatter( deg2rad( ascp(ii).azms(1) ), rr, 'filled', 'MarkerFaceColor', [0.2,0.6,0.2] );
    polarscatter( deg2rad( ascp(ii).azms(1) ), rr, 80, [0.2,0.6,0.2], 'MarkerFaceAlpha', 0.8 );
end

polarplot( -pi:0.1:pi+0.1, 0.6*ones(1,64), '-', 'LineWidth', 1, 'color', [0 0 0] );
polarplot( [-0.2,0,0.2],  [0.6,0.9,0.6], '-', 'LineWidth', 1, 'color', [0 0 0] );
polarplot( deg2rad(linspace(75,105,26)), [0.6:0.01:0.69,0.695,0.7,0.7,0.7,0.7,0.695,0.69:-0.01:0.6], '-', 'LineWidth', 1, 'color', [0 0 0] );
polarplot( deg2rad(linspace(-75,-105,26)), [0.6:0.01:0.69,0.695,0.7,0.7,0.7,0.7,0.695,0.69:-0.01:0.6], '-', 'LineWidth', 1, 'color', [0 0 0] );
set( gca, 'ThetaZeroLocation', 'top' );
set( gca, 'ThetaTick', [0,45,90,135,180,225,270,315] );
set( gca, 'ThetaTickLabel', {'0°','45°','90°','135°','+-180°','-135°','-90°','-45°'} );
set( gca, 'RTick', [] );
set( gca, 'RTickLabel', {} );
set( gca, 'RLim', [0 rr+0.2] );
set( gca, 'Position', [0.05 0.05 0.9 0.9] );
