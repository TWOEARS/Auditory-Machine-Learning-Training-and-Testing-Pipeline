function saveWithNamesRecognized( filepath, allVarsInStruct, varargin )

if ~isstruct( allVarsInStruct )
    error( 'Usage:StructNeeded', '''allVarsInStruct'' needs to be a struct containing the variables to be saved.' );
end

save( filepath, '-struct', allVarsInStruct, varargin{:} );

end
