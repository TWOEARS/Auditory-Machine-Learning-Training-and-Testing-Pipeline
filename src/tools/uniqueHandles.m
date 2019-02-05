function uh = uniqueHandles( handleCell )
% UNIQUEHANDLES returns all unique handles from a cell
%
% handleCell - cell containing handles

%%

if isempty( handleCell )
    uh = {};
    return;
end

uh{1} = handleCell{1};
for ii = 2 : numel( handleCell )
    equalHandleFound = false;
    for jj = 1 : numel( uh )
        if uh{jj} == handleCell{ii}
            equalHandleFound = true;
            break;
        end
    end
    if ~equalHandleFound
        uh{end+1} = handleCell{ii}; %#ok<AGROW>
    end
end


end
