function sc = descriptiveStructCells( s )

fOuterNames = fieldnames( s );
sc = [];
for i = 1:size( fOuterNames, 1 )
    if isstruct( s.(fOuterNames{i}) )
        sctmp = descriptiveStructCells( s.(fOuterNames{i}) );
        sctmp(:,1) = strcat( fOuterNames{i}, '.', sctmp(:,1) );
        sc = [sc; sctmp];
    else
        sc = [sc; {fOuterNames{i} s.(fOuterNames{i})}];
    end
end
