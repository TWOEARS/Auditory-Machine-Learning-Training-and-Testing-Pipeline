
clear;
resDir = {'alarm', 'baby', 'femaleSpeech', 'fire'};

file = load(sprintf('%s/result.mat', resDir{1}));

base = cellstr(num2str([file.res.base]'));
beta = cellstr(num2str([file.res.beta]'));
    
labels = unique(strcat({'b: '},base, {', beta: '}, beta)');
x = 1:12;

for i = 1:length(resDir)
    file = load(sprintf('%s/result.mat', resDir{i}));
    y = [0.4 0.6 0.8 1]; 
    z = reshape([file.res.avgPerformance], 4, []);
    
    figure;
    s = surf(x,y,z,'FaceAlpha',0.9);
    s.EdgeColor = [0.4 0.4 0.4];
    s.FaceColor = 'interp';
    set(gca,'xticklabel',labels, 'xtick', 1:12, 'xticklabelrotation', -45, 'clim',[0.4 1]);
    xlabel('sparse coding model');
    ylabel('sparsity factor \gamma');
    zlabel('avg performance');
    title(resDir{i})
    view( -20, 30);
end
