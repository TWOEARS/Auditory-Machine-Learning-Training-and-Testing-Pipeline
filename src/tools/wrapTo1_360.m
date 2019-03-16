function phi = wrapTo1_360(phi)
%wrapTo360 Wrap angle in degrees to [1 360]
%
% USAGE:
%   phi = wrapTo360(phi)
%
% INPUT PARAMETERS:
%   phi - azimuth angle in deg
%
% OUTPUT PARAMETERS:
%   phi - azmuth angle in deg
%
narginchk(1, 1);
% Ensure 1 <= phi <= 360
phi = mod( mod( phi, 360 ) - 1, 360 ) + 1;

% vim: set sw=4 ts=4 expandtab textwidth=90 :

