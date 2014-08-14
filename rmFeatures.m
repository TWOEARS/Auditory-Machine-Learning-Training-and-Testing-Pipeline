function features = rmFeatures( param, wp2Data )
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean.

rmBlock = wp2Data(strcmp('ratemap_magnitude', vertcat(wp2Data.Name))).Data;
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
