function [lfolds, dfolds, idsfolds] = splitDataPermutation( l, d, ids, folds )

disp( 'splitting data into training/test folds.' );

uniqueIds = unique( ids, 'rows' );
perm = randperm( length( uniqueIds ) );
uniqueIdsPerm = uniqueIds(perm,:);

uniqueClasses = unique( ids(:,2) );

fprintf( '.' );

cfolds{folds} = [];
for i = 1:length( uniqueClasses )
    ucpos = ( uniqueIdsPerm(:,2) == uniqueClasses(i) );
    thisClassIds = uniqueIdsPerm(ucpos);
    share = int64( size( thisClassIds, 1 )/folds );
    for j = 1:folds
        cfolds{j} = [cfolds{j}; thisClassIds(share*(j-1)+1:min(end,share*j))];
    end
end

fprintf( '.' );

dfolds{folds} = [];
lfolds{folds} = [];
idsfolds{folds} = [];
for j = 1:folds
    for i = 1:length( cfolds{j} )
        cpos = ( ids(:,1) == cfolds{j}(i) );
        dfolds{j} = [dfolds{j}; d( cpos,: )];
        lfolds{j} = [lfolds{j}; l( cpos )];
        idsfolds{j} = [idsfolds{j}; ids( cpos,: )];
    end
    fprintf( '.' );
end
    
fprintf( '.' );

for i = 1:folds
    perm = randperm( length(lfolds{i}) );
    lfolds{i} = lfolds{i}(perm);
    dfolds{i} = dfolds{i}(perm,:);
    idsfolds{i} = idsfolds{i}(perm,:);
end

disp( '.' );