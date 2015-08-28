classdef ValGen < matlab.mixin.Copyable & matlab.mixin.Heterogeneous
    
    properties (SetAccess = protected)
        type;   % one of 'manual', 'set', 'random'
        val;    % depending on type: specific value, cell of possible values, or random range
    end
    
    %%
    methods
        
        function obj = ValGen( type, val )
            if sum( strcmpi( type, {'manual', 'set', 'random'} ) ) == 0
                error( 'Type not recognized' );
            end
            obj.type = type;
            obj.val = val;
        end
        
        function instance = instantiate( obj )
            instance = copy( obj );
            if ~isempty( obj )
                instance.type = 'manual';
                instance.val = obj.value();
            end
        end
        
        function val = value( obj )
            switch obj.type
                case 'manual'
                    val = obj.val;
                case 'set'
                    setLen = length( obj.val );
                    randIdx = randi( setLen, 1 );
                    if isa( obj.val, 'cell' )
                        val = obj.val{randIdx};
                    else
                        val = obj.val(randIdx);
                    end
                case 'random'
                    val = rand( 1 ) * (max( obj.val) - min( obj.val )) + min( obj.val );
            end
        end
        
        function e = isequal( obj1, obj2 )
            if isempty( obj1 ) && isempty( obj2 )
                e = true;
                return;
            end
            if isempty( obj1 ) || isempty( obj2 )
                e = false;
                return;
            end
            if ~strcmpi( obj1.type, obj2.type )
                e = false; 
                return; 
            end
            if strcmpi( obj1.type, 'manual' )
                e = isequal( obj1.val, obj2.val );
            else
                e = isequal( sort( obj1.val ), sort( obj2.val ) );
            end
        end
        
    end
    
end
