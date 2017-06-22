function [bac,sens,spec] = breakDownPerformanceDepClassAvg( counts, classVar, vars )

vars = sort( [classVar, vars] );
[bac,sens,spec] = breakDownPerformanceDep( counts, vars );
classVarNew = find( vars == classVar );

bac = squeeze( nanMean( bac, classVarNew ) );
sens = squeeze( nanMean( sens, classVarNew ) );
spec = squeeze( nanMean( spec, classVarNew ) );

end
