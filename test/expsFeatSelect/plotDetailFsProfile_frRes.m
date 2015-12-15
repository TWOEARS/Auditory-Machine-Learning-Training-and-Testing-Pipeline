function plotDetailFsProfile_frRes( featureNames, impacts, addTitle )

baseGrpsBlLen = {{'ratemap','16-ch'},{'onsetStrength','16-ch'},...
                 {'amsFeatures','8-ch'},{'spectralFeatures','32-ch'},...
                 {'ratemap','48-ch'},{'onsetStrength','48-ch'},...
                 {'amsFeatures','24-ch'},{'spectralFeatures','64-ch'}};
fs = [];
nTotal = 0;
for ii = 1 : numel( baseGrpsBlLen )
    grpIdxs = getFeatureIdxs( featureNames, baseGrpsBlLen{ii} );
    grpImpact(ii) = sum( impacts(grpIdxs) );
    nTotal = nTotal + sum( impacts(grpIdxs) > 0 );
end
fig = figure('Name',['Feature Profile frRes' addTitle],'defaulttextfontsize', 12, ...
       'position', [0, 0, 400,400]);
hold all;
hPlot = bar( [grpImpact(1),grpImpact(2),grpImpact(3),grpImpact(4);...
              grpImpact(5),grpImpact(6),grpImpact(7),grpImpact(8)]', ...
    'EdgeColor', 'none',...
    'BarWidth', 0.9,...
    'BarLayout', 'stacked' );
set( gca, 'xtick', [1,2,3,4],'xticklabel', {'ratemap','onset','ams','spectral'} );
set( gca, 'FontSize', 12, 'YGrid', 'on' );
xlabel( 'feature group' );
ylabel( 'impact' );
ylim( gca, [0 0.9] );
% xlim( gca, [1.85 4.1] );
rotateXLabels( gca, 60 );
legend( {'std res', 'high res'}, 'Location', 'Best' );
