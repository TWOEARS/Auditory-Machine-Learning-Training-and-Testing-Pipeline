function [bac,sens,spec] = breakDownPerformanceDepClassAvg( counts, classVar, vars )

vars = sort( [classVar, vars] );
[bac,sens,spec] = breakDownPerformanceDep( counts, vars );
classVarNew = find( vars == classVar );

bac = mean( bac, classVarNew );
sens = mean( sens, classVarNew );
spec = mean( spec, classVarNew );

end
