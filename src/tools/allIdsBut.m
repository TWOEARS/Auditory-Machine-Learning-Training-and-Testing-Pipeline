function ids = allIdsBut( idDescr, excludeIdFields )

idDescr_ = rmfield( idDescr, excludeIdFields );
idFields = fieldnames( idDescr_ );
ids = cellfun( @(c)(idDescr_.(c)), idFields );

end