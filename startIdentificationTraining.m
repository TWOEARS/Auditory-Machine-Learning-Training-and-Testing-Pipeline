function startIdentificationTraining
% This function initialises the path variables that are needed for running
% the Identification Training Pipeline of the Two!Ears Blackboard System
% module

startTwoEars( 'IdentificationTraining.xml' );

basePath = fileparts(mfilename('fullpath'));

% Add all relevant folders to the matlab search path
addPathsIfNotIncluded( ...
    [ strsplit( genpath( fullfile( basePath, 'src') ), ';' ) ...
      strsplit( genpath( fullfile( basePath, 'third_party_software') ), ';' )] ...
      );
