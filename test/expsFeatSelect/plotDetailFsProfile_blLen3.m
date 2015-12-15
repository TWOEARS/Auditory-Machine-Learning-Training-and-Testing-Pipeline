function plotDetailFsProfile_blLen3( featureNames, impacts, addTitle )

allGrps = getFeatureGrps( featureNames );
fGrpsL = cellfun( @(c)(c(1)=='f' && ~isempty( str2num( c(2) ) )), allGrps );
fGrps = allGrps(fGrpsL);
fGrpsNum = cellfun( @(c)( str2num( c(2:end) ) ), fGrps );
[fGrpsNum,sortIdx] = sort( fGrpsNum );
fGrps = fGrps(sortIdx);
fsbl1 = [];
fsbl2 = [];
fsbl3 = [];
nTotal = 0;
for ii = 1 : numel( fGrps )
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'blLen 0.2'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsbl1 = [fsbl1 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'blLen 0.5'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsbl2 = [fsbl2 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'blLen 1'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsbl3 = [fsbl3 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    fprintf('.\n');
end
binr = [100 133 200 266 400 533 800 1066 1600 2133 3200 4266 6400 10000];
bincbl1 = histc( fsbl1, binr ) / 1000;
bincbl2 = histc( fsbl2, binr ) / 1000;
bincbl3 = histc( fsbl3, binr ) / 1000;
fig = figure('Name',['Feature Profile freq' addTitle],'defaulttextfontsize', 12, ...
       'position', [0, 0, 800,600] );
title( 'features over frequency' );
hold all;
hPlot = bar( log10(binr), [bincbl1',bincbl2',bincbl3'], ...
    ...%'FaceColor', [0.3 0.3 0.3], ...
    'EdgeColor', 'none',...
    'BarWidth', 0.9,...
    'BarLayout', 'stacked' );
set( gca, 'xtick',log10(binr),'xticklabel', round(binr) );
set( gca, 'FontSize', 12, 'YGrid', 'on' );
xlabel( 'freq (upper end of bin)' );
ylabel( 'impact' );
ylim( gca, [0 0.4] );
xlim( gca, [1.85 4.1] );
rotateXLabels( gca, 60 );
legend( {'0.2s', '0.5s', '1.0s'}, 'Location', 'Best' );
savePng( ['fsProf_' addTitle] );