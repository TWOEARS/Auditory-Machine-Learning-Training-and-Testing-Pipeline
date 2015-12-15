function plotDetailFsProfile_blLen2( featureNames, impacts, addTitle )

allGrps = getFeatureGrps( featureNames );
fGrpsL = cellfun( @(c)(c(1)=='f' && ~isempty( str2num( c(2) ) )), allGrps );
fGrps = allGrps(fGrpsL);
fGrpsNum = cellfun( @(c)( str2num( c(2:end) ) ), fGrps );
[fGrpsNum,sortIdx] = sort( fGrpsNum );
fGrps = fGrps(sortIdx);
fsRMbl1 = [];
fsAMbl1 = [];
fsOMbl1 = [];
fsRMbl2 = [];
fsAMbl2 = [];
fsOMbl2 = [];
fsRMbl3 = [];
fsAMbl3 = [];
fsOMbl3 = [];
nTotal = 0;
for ii = 1 : numel( fGrps )
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'ratemap','blLen 0.2'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsRMbl1 = [fsRMbl1 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'amsFeatures','blLen 0.2'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsAMbl1 = [fsAMbl1 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'onsetStrength','blLen 0.2'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsOMbl1 = [fsOMbl1 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    fprintf('.');
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'ratemap','blLen 0.5'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsRMbl2 = [fsRMbl2 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'amsFeatures','blLen 0.5'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsAMbl2 = [fsAMbl2 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'onsetStrength','blLen 0.5'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsOMbl2 = [fsOMbl2 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    fprintf('.');
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'ratemap','blLen 1'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsRMbl3 = [fsRMbl3 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'amsFeatures','blLen 1'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsAMbl3 = [fsAMbl3 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    grpIdxs = getFeatureIdxs( featureNames, {fGrps{ii},'onsetStrength','blLen 1'} );
    grpImpact = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
    fsOMbl3 = [fsOMbl3 ones(1,round(grpImpact*1000))*fGrpsNum(ii)];
    fprintf('.\n');
end
binr = [100 133 200 266 400 533 800 1066 1600 2133 3200 4266 6400 10000];
bincRMbl1 = histc( fsRMbl1, binr ) / 1000;
bincAMbl1 = histc( fsAMbl1, binr ) / 1000;
bincOMbl1 = histc( fsOMbl1, binr ) / 1000;
bincRMbl2 = histc( fsRMbl2, binr ) / 1000;
bincAMbl2 = histc( fsAMbl2, binr ) / 1000;
bincOMbl2 = histc( fsOMbl2, binr ) / 1000;
bincRMbl3 = histc( fsRMbl3, binr ) / 1000;
bincAMbl3 = histc( fsAMbl3, binr ) / 1000;
bincOMbl3 = histc( fsOMbl3, binr ) / 1000;
fig = figure('Name',['Feature Profile freq' addTitle],'defaulttextfontsize', 12, ...
       'position', [0, 0, 800,600],...
       'Colormap',[0 0 0.800000011920929;0 0 0.866666674613953;0 0 0.933333337306976;0 0 1;0 0.0526315793395042 1;0 0.105263158679008 1;0 0.157894730567932 1;0 0.210526317358017 1;0 0.263157904148102 1;0 0.315789461135864 1;0 0.368421047925949 1;0 0.421052634716034 1;0 0.473684221506119 1;0 0.526315808296204 1;0 0.578947365283966 1;0 0.631578922271729 1;0 0.684210538864136 1;0 0.736842095851898 1;0 0.789473712444305 1;0 0.842105269432068 1;0 0.89473682641983 1;0 0.947368443012238 1;0 1 1;0.105882354080677 0.309803932905197 0.207843139767647;0.134963229298592 0.344313740730286 0.21307598054409;0.164044111967087 0.378823548555374 0.218308821320534;0.193124994635582 0.413333356380463 0.223541662096977;0.222205877304077 0.447843134403229 0.228774517774582;0.251286774873734 0.482352942228317 0.234007358551025;0.280367642641068 0.516862750053406 0.239240199327469;0.309448540210724 0.551372528076172 0.244473040103912;0.338529407978058 0.585882365703583 0.249705880880356;0.367610305547714 0.620392143726349 0.254938721656799;0.396691173315048 0.65490198135376 0.260171562433243;0.425772070884705 0.689411759376526 0.265404403209686;0.454852938652039 0.723921597003937 0.27063724398613;0.483933836221695 0.758431375026703 0.275870084762573;0.513014733791351 0.792941153049469 0.281102955341339;0.542095601558685 0.82745099067688 0.286335796117783;0.571176469326019 0.861960768699646 0.291568636894226;0.600257337093353 0.896470606327057 0.29680147767067;0.629338264465332 0.930980384349823 0.302034318447113;0.658419132232666 0.965490221977234 0.307267159223557;0.6875 1 0.3125;0.600000023841858 0 0;0.64000004529953 0.0399999991059303 0;0.680000007152557 0.0799999982118607 0;0.720000028610229 0.120000004768372 0;0.759999990463257 0.159999996423721 0;0.800000011920929 0.200000002980232 0;0.840000033378601 0.240000009536743 0;0.879999995231628 0.280000001192093 0;0.920000016689301 0.319999992847443 0;0.959999978542328 0.360000014305115 0;1 0.400000005960464 0;1 0.444444447755814 0.0444444455206394;1 0.488888889551163 0.0888888910412788;1 0.533333361148834 0.133333340287209;1 0.577777802944183 0.177777782082558;1 0.622222244739532 0.222222223877907;1 0.666666686534882 0.266666680574417;1 0.711111128330231 0.311111122369766;1 0.75555557012558 0.355555564165115;1 0.800000011920929 0.400000005960464]);
title( 'features over frequency' );
hold all;
hPlot = bar( log10(binr), [bincRMbl1',bincRMbl2',bincRMbl3',...
                           bincOMbl1',bincOMbl2',bincOMbl3',...
                           bincAMbl1',bincAMbl2',bincAMbl3'], ...
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
legend( {'ratemap 0.2s', 'ratemap 0.5s', 'ratemap 1.0s',...
         'onsetStrength 0.2s', 'onsetStrength 0.5s', 'onsetStrength 1.0s',...
         'amplitude modulation0.2s', 'amplitude modulation 0.5s', 'amplitude modulation 1.0s'}, 'Location', 'Best' );
savePng( ['fsProf_' addTitle] );