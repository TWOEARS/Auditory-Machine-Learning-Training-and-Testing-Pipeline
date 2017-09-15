clear;

labels = {'alarm', 'baby', 'femaleSpeech', 'fire'};

path = 'diverse/b368_0.4_0.4_20000_20it 180000samples';
%PlotResultsByClass(path, labels);
PlotResultsOverall(path, labels, 10:10:100);

path = 'diverse/b368_0.4_0.4_inf_20it 180000samples';
%PlotResultsByClass(path, labels);
PlotResultsOverall(path, labels, 10:10:100);

path = 'diverse/b368_0.4_0.4_inf_100it 180000samples';
%PlotResultsByClass(path, labels);
PlotResultsOverall(path, labels, 10:10:100);
