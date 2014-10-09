function features = msFeatures( param, auditoryFrontEndData )
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

rmBlock = auditoryFrontEndData(strcmp('ratemap_magnitude', vertcat(auditoryFrontEndData.Name))).Data;
for ci = 1 : size(rmBlock,2)
    rmBlock{ci} = rmBlock{ci}.^0.33; %cuberoot compression
    scale = max(max(abs(rmBlock{ci})));
    if ~( any(scale==0) || any(~isfinite(scale)) )
        rmBlock{ci} = rmBlock{ci}./repmat(scale,size(rmBlock{ci}));
    end
end

% TODO: determine which channel to use!
s = .5 * rmBlock{1} + .5 * rmBlock{2};
features = [mean( s, 1 )  std( s, 0, 1 )];
for i = 1:param.derivations
    s = s(2:end,:) - s(1:end-1,:);
    features = [features  mean( s, 1 )  std( s, 0, 1 )];
end
