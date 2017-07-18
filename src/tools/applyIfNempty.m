function res = applyIfNempty( x, fun )

if isempty( x )
    res = [];
    return;
end

res = fun( x );

end