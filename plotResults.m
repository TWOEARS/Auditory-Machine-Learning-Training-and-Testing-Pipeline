
clear;
resDir = {'alarm', 'baby', 'femaleSpeech', 'fire'};

file = load(sprintf('%s/result.mat', resDir{1}));

base = cellstr(num2str([file.res.base]'));
beta = cellstr(num2str([file.res.beta]'));

labels = strcat({'b: '},base, {', beta: '}, beta)';
x = 1:12;

for i = 1:length(resDir)
    file = load(sprintf('%s/result.mat', resDir{i}));
    y = [0.4 0.6 0.8 1]; 
    z = reshape([file.res.avgPerformance], 4, []);
    
    figure;
    s = surf(x,y,z,'FaceAlpha',0.9);
    s.EdgeAlpha = 0.9;
    s.EdgeColor = [0.5 0.5 0.5];
    colorbar;
    set(gca,'xticklabel',labels, 'xtick', 1:12, 'xticklabelrotation', 45);
    xlabel('sparse coding model')
    ylabel('sparsity factor \gamma')
end