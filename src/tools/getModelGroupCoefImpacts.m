function [cImpacts,featureDescription] = getModelGroupCoefImpacts( modelpathes )

fd = [];

for mm = 1 : numel( modelpathes )
    fprintf( '.' );
    mf = load( modelpathes{mm} );
    fd_ = fd;
    fd = mf.featureCreator.description;
    if ~isempty( mf.model.featureMask )
        fd = fd(mf.model.featureMask);
    end
    if mm > 1 && ~isequal( fd, fd_ )
        error( 'Models have different feature descriptions.' );
    end
    if mm == 1
        cis = zeros( numel( modelpathes ), numel( fd ) );
    end
    [ci,ciidx] = mf.model.getCoefImpacts();
    cis(mm,ciidx) = ci;
end

assert( all( abs( sum( cis, 2 ) - 1 ) < 1e-6 ) );

cImpacts = mean( cis, 1 );
featureDescription = fd;

fprintf( ';\n' );

end
