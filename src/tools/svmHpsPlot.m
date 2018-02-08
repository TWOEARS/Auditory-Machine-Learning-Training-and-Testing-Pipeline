function svmHpsPlot( c, g, perf )

c = log10( c );
g = log10( g );

figure;
[ctri,h] = tricontour( delaunay( c, g ), c, g, perf, logspace( log10( min( perf ) ), log10( max( perf ) - 0.01 ), 10 ) );
for ii = 1 : numel( h )
    set( h(ii), 'LineWidth', 2 );
end
set( h(1), 'LineWidth', 3, 'FaceColor', get( h(1), 'EdgeColor' ) );
% clabel( ctri );
xlabel( 'log10( C )' );
ylabel( 'log10( gamma )' );
hold on;
scatter( c, g );
[~,idx] = max( perf );
scatter( c(idx), g(idx), 'filled' );
colorbar();

end
