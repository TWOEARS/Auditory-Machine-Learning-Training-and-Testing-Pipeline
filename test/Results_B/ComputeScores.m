clear;
files = dir('*_results.mat');

data = load(files(1).name);
scores = struct;
for i=1:length(files)
    data = load(files(i).name);
    for j=1:length(data.res)
        if i == 1
            scores(j).base = data.res(j).base;
            scores(j).beta = data.res(j).beta;
            scores(j).new  = data.res(j).new;
            scores(j).score = data.res(j).avgPerformance;
        else 
            scores(j).score = scores(j).score + data.res(j).avgPerformance;
        end
    end
        
end

save('scores.mat', 'scores');