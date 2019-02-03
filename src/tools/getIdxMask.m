function idxMask = getIdxMask( idxSize, varargin )

idxMask = repmat( {':'}, 1, idxSize );

for aa = 1:2:numel( varargin )
    idxMask{varargin{aa}} = varargin{aa+1};
end

end
