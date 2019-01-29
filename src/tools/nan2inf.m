function v = nan2inf( v )
v(isnan( v ))= inf;
end