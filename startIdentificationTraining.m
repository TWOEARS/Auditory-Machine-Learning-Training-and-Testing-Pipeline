% This script initialises the path variables that are needed for running
% the Identification Training Pipeline of the Two!Ears Blackboard System
% module

basePath = fileparts(mfilename('fullpath'));

% Add all relevant folders to the matlab search path
addpath(fullfile(basePath, 'src'));
addpath(fullfile(basePath, 'src', '+core'));
addpath(fullfile(basePath, 'src', '+dataProcs'));
addpath(fullfile(basePath, 'src', 'evaluation'));
addpath(fullfile(basePath, 'src', '+featureCreators'));
addpath(fullfile(basePath, 'src', '+models'));
addpath(fullfile(basePath, 'src', '+modelTrainers'));
addpath(fullfile(basePath, 'src', '+performanceMeasures'));
addpath(fullfile(basePath, 'src', 'postpros'));
addpath(fullfile(basePath, 'src', 'trainingScripts'));

clear basePath;
