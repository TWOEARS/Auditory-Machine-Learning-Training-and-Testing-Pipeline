function results_sc_fs_profiles

impacts_dwn = cell(4,11,2,7); % fc, class, bOrHws, snr


%% 'RESULTS_feature_impact_FeatureSet1*_fs*.mat'
load('RESULTS_feature_impact_FeatureSet1VarBlocks_fs3.mat');
impacts_dwn(3,:,1,:) = IMP;
load('RESULTS_feature_impact_FeatureSet1VarBlocks_fs1.mat');
impacts_dwn(3,:,2,:) = IMP;
load('RESULTS_feature_impact_FeatureSet1Blockmean_fs3.mat');
impacts_dwn(2,:,1,:) = IMP;
load('RESULTS_feature_impact_FeatureSet1Blockmean_fs1.mat');
impacts_dwn(2,:,2,:) = IMP;

impacts_dwn_std = impacts_dwn;
impacts_dwn = cellSqueezeFun( @(c)(mean( [c{:}],2 )), impacts_dwn, 2 );
impacts_dwn_std = cellSqueezeFun( @(c)(std( [c{:}],[],2 )), impacts_dwn_std, 2 );

%% grp defs

baseGrps = {{'ratemap'},{'onsetStrength'},{'amsFeatures'},{'spectralFeatures'}};
baseGrpsBlLen = {{'ratemap','blLen 0.2'},{'onsetStrength','blLen 0.2'},{'amsFeatures','blLen 0.2'},{'spectralFeatures','blLen 0.2'}};

%% all classes, all fcs

% for fc = [1]
%     for cc = 2
%         switch fc
%             case 1
%                 load( '../fnames_fs1blockmean.mat' );
% %             case
% %                 load( '../fnames_fs1bm2channel.mat' );
%             case 2
%                 load( '../fnames_fs1varBlocks.mat' );
%             case 3
%                 load( '../fnames_fs1LowVsHighFreqRes.mat' );
%         end
% %         plotFsProfileExplore( impacts_mc{fc,cc,1}, featureNames, ['fs1: class ' num2str(cc) ', fc ' num2str(fc)] );
% %         plotFsProfileExplore( impacts_mc{fc,cc,2}, featureNames, ['fs3: class ' num2str(cc) ', fc ' num2str(fc)] );
% %         plotFsGrps( baseGrps, impacts_mc{fc,cc,1}, featureNames,...
% %             ['fs1: class ' num2str(cc) ', fc ' num2str(fc)]);
% %         plotFsGrps( baseGrps, impacts_mc{fc,cc,2}, featureNames,...
% %             ['fs3: class ' num2str(cc) ', fc ' num2str(fc)]);
% %         plotDetailFsProfile( featureNames, impacts_mc{fc,cc,1}, ...
% %             ['detail;fs1: class ' num2str(cc) ', fc ' num2str(fc)]);
%         plotDetailFsProfile( featureNames, impacts_dwn{fc,cc,2}, ...
%             ['detail;fs3: class ' num2str(cc) ', fc ' num2str(fc)]);
%     end
% end

%%

load( '../fnames_fs1blockmean.mat' );
% load( '../fnames_fs1varBlocks.mat' );

grpDefs = baseGrps;
grpImpact = zeros( 7, 4 );
grpImpactStd = zeros( 7, 4 );
grpCount = zeros( 7, 4 );


for ss = 1 : 7
% plotDetailFsProfile( featureNames, impacts_dwn{2,1,1,ss}, ...
%                      ['detail;fs3: mean over classes, Monaural']);
impacts = impacts_dwn{2,1,1,ss};
impactsStd = impacts_dwn_std{2,1,1,ss};

for ii = 1 : numel( grpDefs )
    grpIdxs = getFeatureIdxs( featureNames, grpDefs{ii} );
    grpImpact(ss,ii) = sum( impacts(grpIdxs) );
    grpImpactStd(ss,ii) = mean( impactsStd(grpIdxs) );
    grpCount(ss,ii) = sum( impacts(grpIdxs) > 0 );
end

% plotFsGrps( baseGrpsBlLen, impacts_dwn{2,1,1,ss}, featureNames, ...
%            'fs3: mean over classes, Monaural' );
% plotDetailFsProfile_blLen( featureNames, impacts_dwn{3,1,1,ss}, ...
%                            ['detail;fs3: mean over classes, VarBlockLengths']);

end

figure( 'Name', 'Impact of feature groups over SNRs under DWN' );
hold all;
snrs = [inf,20,10,5,0,-10,-20];
plot( snrs, grpImpact, 'LineWidth', 2, 'Marker', 'x' );
xlabel( 'SNR in dB', 'FontSize', 14 );
ylabel( 'impact of feature group', 'FontSize', 14 );
ylim( [-0.05 0.8] );
xlim( [-22 22] );
set( gca, 'XTick', [-20 -10 0 5 10 20], 'XDir', 'reverse', 'FontSize', 14);
legend( {'Ratemap','Onset Strength','Amplitude Modulation','Spectral'},'Location','Best' );

%% frequency profiles (fc1 vs fc3)

%% which spectral features

%% which blocklengths, and which basegroups in which blocklengths

%% stacked bars for bl and fr

%% stacked line plot #impact/group over performance
