clear;

labels = {'alarm', 'baby', 'femaleSpeech', 'fire'};

path = 'diverse/b100_0.4_0.4_20000 20000samples';
PlotResultsByClass(path, labels);
%PlotResultsOverall(path, labels, 10:10:100);

path = 'diverse/b100_0.4_0.4_100000_inclNigens 20000samples';
PlotResultsByClass(path, labels);
%PlotResultsOverall(path, labels, 10:10:100);

%path = 'diverse/b368_0.4_0.4_inf_100it 180000samples';
%PlotResultsByClass(path, labels);
%PlotResultsOverall(path, labels, 10:10:100);
