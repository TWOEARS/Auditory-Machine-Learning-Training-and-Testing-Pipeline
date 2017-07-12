function p = pathInsert( p, pinsert, level )

pSeps = strfind( p, '/' );
p = cleanPathFromRelativeRefs( [p(1:pSeps(end+level)) pinsert '/' p(pSeps(end+level)+1:end)] );
