path = {'diversity_0.1/', 'diversity_0.3/', 'Results b100_0.4_0.4_maxData20000/'};
entry = {'317 sound files', '952 sound files', '3174 sound files'};
colors = {'r', 'g', 'b'};
lines = {'-x', '-o', '-*'};
portions = 0.1:0.1:1;
figure;
hold on; 
for i=1:length(path)
    data = load([path{i} 'STLComparison_overall.mat']);
    overall = data.overall;
    meanSTL = overall.meanSTL;
    varSTL = overall.varSTL;
    
    %plot line and shaded error area
    p(i) = plot( portions, meanSTL , strcat(colors{i}, lines{i}) );
    errorArea( portions, meanSTL - sqrt(varSTL),...
        meanSTL + sqrt(varSTL), colors{i} );
    
end

% description
xlabel('portion of sound files for training in %');
ylabel('classification performance');
title('influence of unlabeled data on performance');
legend(p, { entry{1}, entry{2}, entry{3}}, 'Location','southeast');