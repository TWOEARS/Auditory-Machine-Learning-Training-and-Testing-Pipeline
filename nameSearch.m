function [fname, fname2] = nameSearch(p)

pos = strfind(p,'/');

fname = p(pos(end)+1:end);
fname2 = p(pos(end-1)+1:end);