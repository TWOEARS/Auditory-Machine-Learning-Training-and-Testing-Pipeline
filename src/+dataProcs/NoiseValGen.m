classdef NoiseValGen < dataProcs.ValGen

    %%
    methods
        
        function obj = NoiseValGen( val )
            if ~( isfield( val, 'len' ) && isa( val.len, 'dataProcs.ValGen' ) )
                error( 'val does not provide all needed fields' );
            end
            obj = obj@dataProcs.ValGen( 'manual', val );
            obj.type = 'specific';
        end
        
        function val = value( obj )
            len = floor( obj.val.len.value() );
            val = rand( len, 1 ) * 2 - 1;
        end
        
    end
    
    %%
    methods (Access = protected)
        
        
    end
    
end
