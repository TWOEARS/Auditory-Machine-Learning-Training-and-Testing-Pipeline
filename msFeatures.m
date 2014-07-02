function features = msFeatures( param, wp2Data )
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

rmBlock = wp2Data(strcmp('ratemap_magnitude', vertcat(wp2Data.name))).data;
rmBlock = rmBlock.^0.33; %cuberoot compression
for ii = 1 : size(rmBlock,3)
    scale = max(max(abs(rmBlock(:,:,ii))));
    if any(scale==0) || any(~isfinite(scale))
        rmBlock(:,:,ii) = rmBlock(:,:,ii);
    else
        rmBlock(:,:,ii) = rmBlock(:,:,ii)./repmat(scale,size(rmBlock(:,:,ii)));
    end
end

% TODO: determine which channel to use!
s = .5 * rmBlock(:,:,1) + .5 * rmBlock(:,:,2);
features = [mean( s, 2 ); std( s, 0, 2 )];
for i = 1:param.derivations
    s = s(:,2:end) - s(:,1:end-1);
    features = [features; mean( s, 2 ); std( s, 0, 2 )];
end
