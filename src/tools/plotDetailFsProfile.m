function plotDetailFsProfile( featureNames, impacts, addTitle, bSave )
% PLOTDETAILFSPROFILE plot (and optionally save) detailed feature impact
% profiles
%
% featureNames - feature set description as produced by AMLTTP
% featureCreators
% impacts - impact values for each feature
% addTitle 
% bSave - whether or not to save as png

%%
allGrps = getFeatureGrps( featureNames );
fGrpsL = cellfun( @(c)(c(1)=='f' && ~isempty( str2num( c(2) ) )), allGrps );
fGrps = allGrps(fGrpsL);
fGrpsNum = cellfun( @(c)( str2num( c(2:end) ) ), fGrps );
[fGrpsNum,sortIdx] = sort( fGrpsNum );
fGrps = fGrps(sortIdx);
fsRM = [];
fsAM = [];
fsOM = [];
nTotal = 0;
for ii = 1 : numel( fGrps )
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'ratemap'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsRM = [fsRM ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'amsFeatures'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsAM = [fsAM ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'onsetStrength'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsOM = [fsOM ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
end
binr = [120 200 300 450 600 800 1000 1300 1650 2100 2700 3300 4200 5200 6500 8000];
bincRM = histcounts( fsRM, [0 binr] ) / 1000;
bincAM = histcounts( fsAM, [0 binr] ) / 1000;
bincOM = histcounts( fsOM, [0 binr] ) / 1000;
fig = figure('Name',['Feature Profile freq' addTitle],'defaulttextfontsize', 12, ...
       'position', [0, 0, 800,600]);
subplot(6,100,[1:55,101:155,201:255,301:355,401:455]);
title( 'features over frequency' );
hold all;
hPlot = bar( log10(binr), [bincRM',bincOM',bincAM'], ...
    ...%'FaceColor', [0.3 0.3 0.3], ...
    'EdgeColor', 'none',...
    'BarWidth', 1.0,...
    'BarLayout', 'stacked' );
set( gca, 'xtick',log10(binr),'xticklabel', round(binr) );
set( gca, 'FontSize', 12, 'YGrid', 'on' );
xlabel( 'freq (upper end of bin)' );
ylabel( 'grp impact' );
ylim( gca, [0 0.7] );
xlim( gca, log10([100 8800]) );
rotateXLabels( gca, 60 );
legend( {'ratemap', 'onsetStrength', 'amplitude modulation'}, 'Location', 'Best' );
op = get( gca, 'OuterPosition');
ip = get( gca, 'Position');
subplot(6,100,[375:400,475:500]);
title( 'ams modulation freqs' );
mfGrpsL = cellfun( @(c)(c(1)=='m' && c(2)=='f' && ~isempty( str2num( c(3) ) )), allGrps );
mfGrps = allGrps(mfGrpsL);
mfGrpsNum = cellfun( @(c)( str2num( c(3:end) ) ), mfGrps );
[mfGrpsNum,sortIdx] = sort( mfGrpsNum );
mfGrps = mfGrps(sortIdx);
mfGrps = cellfun( @(c)({{c}}), mfGrps );
plotFsGrps( mfGrps, impacts, featureNames, addTitle, true, true );
subplot(6,100,[75:100,175:200]);
sfGrps = {{'centroid'},{'crest'},{'spread'},{'entropy'},{'brightness'},{'hfc'},{'decrease'},...
          {'flatness'},{'flux'},{'kurtosis'},{'skewness'},{'irregularity'},{'rolloff'},{'variation'}};
plotFsGrps( sfGrps, impacts, featureNames, addTitle, false, true, 'pie' );
title( 'spectral features' );
annotation( gcf, 'textbox',...
    [ip(1)-0.1 op(2)-0.1 0.01 0.05],...
    'String',{['#total ' num2str(nTotal)]},...
    'FontSize',12,...
    'FitBoxToText','off',...
    'EdgeColor','none');

if nargin >= 4 && bSave
    savePng( ['fsProf_' addTitle] );
end
