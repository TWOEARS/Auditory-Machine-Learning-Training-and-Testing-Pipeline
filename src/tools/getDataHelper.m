function d = getDataHelper( dataset, dataField )

if isa( dataset, 'Core.IdentTrainPipeData' )
    d = dataset(:,dataField);
elseif isstruct( dataset ) && isfield( dataset, dataField )
    d = dataset.(dataField);
else
    error( 'AMLTTP:ApiUsage', 'improper usage of getDataHelper' );
end

end
% -----------------------------------------------------------------
