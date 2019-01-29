function varargout = applyIfNempty( x, fun )
% APPLYIFNEMPTY utility function particularly for applying functions with
% cellfun to cell arrays that might have empty cells
%
% use like:
% a = cellfun( @(c)(applyIfNempty(c,@yourFun), ca, 'UniformOutput', false );

%%
if isempty( x )
    varargout(1:nargout) = cell( 1, nargout );
    return;
end

[varargout{1:nargout}] = fun( x );

end