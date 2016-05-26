startIdentificationTraining;
target_azimuths = [-90, -45, 0, 45, 90];
for ii=1:length(target_azimuths)
    feat_creator = featureCreators.FeatureSetRawRmAmsLRSeparate();
    [modelPath_train{ii}, modelPath_test{ii}] = gen_clean_at_azimuth( target_azimuths(ii), feat_creator );
end

save('modelPath.mat', 'modelPath_train', 'modelPath_test');
