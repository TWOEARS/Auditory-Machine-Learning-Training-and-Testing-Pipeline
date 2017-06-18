function xsummed = summarizeDown( x, leaveVariables )
    dims = 1 : ndims( x );
    dims([leaveVariables,10]) = [];
    dims = flip( dims );
    xsummed = x;
    for dd = dims
        xsummed = sum( xsummed, dd );
    end
    xsummed = squeeze( xsummed );
end

