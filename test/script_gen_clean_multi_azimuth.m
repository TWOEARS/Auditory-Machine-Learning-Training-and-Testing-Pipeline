startIdentificationTraining;
target_azimuths = [-90, -45, 0, 45, 90];
for ii=1:length(target_azimuths)
    feat_creator = featureCreators.FeatureSetRawRmAmsLRSeparate();
    modelPath_lr_separate{ii} = gen_clean_at_azimuth( target_azimuths(ii), feat_creator );
end

save('modelPath_lr_separate.mat', 'modelPath_lr_separate');
