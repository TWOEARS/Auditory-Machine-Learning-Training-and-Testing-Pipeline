function x = scaleData( x, translators, factors )

x = x - repmat( translators, size(x,1), 1 );
x = x .* repmat( factors, size(x,1), 1 );