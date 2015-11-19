function results_mc_fs_profiles

impacts_mc = cell(3,4,2); % fc, class, bOrHws

%% 'glmnet_mc1_test.mat'
load('glmnet_mc1_test.mat')

impacts_mc(:,:,1) = impacts_b;
impacts_mc(:,:,2) = impacts_hws;


%% grp defs

baseGrps = {{'ratemap'},{'onsetStrength'},{'amsFeatures'},{'spectralFeatures'}};

%% all classes, all fcs

for fc = [1,3]
    for cc = 2
        switch fc
            case 1
                load( '../fnames_fs1blockmean.mat' );
%             case
%                 load( '../fnames_fs1bm2channel.mat' );
            case 2
                load( '../fnames_fs1varBlocks.mat' );
            case 3
                load( '../fnames_fs1LowVsHighFreqRes.mat' );
        end
%         plotFsProfileExplore( impacts_mc{fc,cc,1}, featureNames, ['fs1: class ' num2str(cc) ', fc ' num2str(fc)] );
%         plotFsProfileExplore( impacts_mc{fc,cc,2}, featureNames, ['fs3: class ' num2str(cc) ', fc ' num2str(fc)] );
%         plotFsGrps( baseGrps, impacts_mc{fc,cc,1}, featureNames,...
%             ['fs1: class ' num2str(cc) ', fc ' num2str(fc)]);
%         plotFsGrps( baseGrps, impacts_mc{fc,cc,2}, featureNames,...
%             ['fs3: class ' num2str(cc) ', fc ' num2str(fc)]);
%         plotDetailFsProfile( featureNames, impacts_mc{fc,cc,1}, ...
%             ['detail;fs1: class ' num2str(cc) ', fc ' num2str(fc)]);
        plotDetailFsProfile( featureNames, impacts_mc{fc,cc,2}, ...
            ['detail;fs3: class ' num2str(cc) ', fc ' num2str(fc)]);
    end
end

%% frequency profiles (fc1 vs fc3)

%% which spectral features

%% which blocklengths, and which basegroups in which blocklengths

%% stacked bars for bl and fr

%% stacked line plot #impact/group over performance
