
clear;

file = load('scores.mat');

base = cellstr(num2str([file.scores.base]'));
beta = cellstr(num2str([file.scores.beta]'));
    
labels = strcat({'b: '},base(1:4:end), {', beta: '}, beta(1:4:end))';
x = 1:12;
y = [0.4 0.6 0.8 1]; 
z = reshape([file.scores.score], 4, []);

s = surf(x,y,z,'FaceAlpha',0.9);
s.EdgeColor = [0.4 0.4 0.4];
s.FaceColor = 'interp';
set(gca,'xticklabel',labels, 'xtick', 1:12, 'xticklabelrotation', 45);
xlabel('sparse coding model');
ylabel('sparsity factor \gamma');
zlabel('score');
title('scores');
colorbar;
view(20, 30);


