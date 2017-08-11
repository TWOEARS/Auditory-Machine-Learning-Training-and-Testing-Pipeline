
clear;
modelDir = {'alarm', 'baby', 'femaleSpeech', 'fire'};
for index = 1:length(modelDir)
    files = dir( sprintf('%s/STLTest*.mat', modelDir{index}));
    j = 1;
    res = struct;
    for i=1:length(files)    
        file = files(i);
        data = load( sprintf('%s/%s', modelDir{index}, file.name) );
        % extract hps from file name
        splitted = strsplit(file.name, '_');
        base = str2double(splitted{2}(2:end));
        beta = str2double(splitted{3}(5:end));
        new = str2double(splitted{4}(4:end));
        % get performance
        performance = data.testPerfresults.performance;

        if ~ (i == 1)
            idx = [res.beta] == beta & [res.base] == base & [res.new] == new;
        else 
            idx = 0;
        end
        if any(idx)
            res(idx).performance( length(res(idx).performance) + 1 ) = performance;
            res(idx).avgPerformance = mean(res(idx).performance);
            res(idx).variance = var(res(idx).performance);
        else
            res(j).base = base;
            res(j).beta = beta;
            res(j).new = new;
            res(j).performance(1) = performance;
            res(j).avgPerformance = performance;
            res(j).variance = 0;
            j = j + 1;
        end
    end
    save(sprintf('%s/result.mat', modelDir{index}), 'res');    
end