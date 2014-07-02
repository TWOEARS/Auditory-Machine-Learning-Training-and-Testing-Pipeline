function c = stringifyCell( c )

for i = 1:size(c,1)
    if isa( c{i}, 'function_handle' )
        c{i} = func2str( c{i} );
    end
    if isa( c{i}, 'cell' ) && ~isempty( c{i} )
        if size( c{1}, 2 ) > 1
            c(i) = {strcat( c{i}{:}, ' ' )};
        else
            c(i) = c{i};
        end
    end
    if isa( c{i}, 'numeric' ) || isa( c{i}, 'logical' )
        c{i} = mat2str( c{i} );
    end
end
