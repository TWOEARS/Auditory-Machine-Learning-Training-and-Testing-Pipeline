function extract = extractChannel( combined, channelIndex )

switch ndims(combined)
    case 2
        extract = combined(:,channelIndex);
    case 3
        extract = combined(:,:,channelIndex);
    otherwise
        disp( 'not implemented' );
        assert( false );
end
