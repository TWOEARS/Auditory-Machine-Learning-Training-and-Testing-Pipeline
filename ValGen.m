classdef ValGen < handle

    properties
        type;   % one of 'manual', 'set', 'random'
        val;    % depending on type: specific value, array of possible values, or random range
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
        
        function val = genVal( obj )
            switch obj.type
                case 'manual'
                    val = obj.genManual();
                case 'set'
                    val = obj.genSet();
                case 'random'
                    val = obj.genRandom();
            end
        end

    end
    
    %%
    methods (Access = protected)
        
        function val = genManual( obj )
            val = obj.val;
        end
        
        function val = genSet( obj )
            setLen = size( obj.val, 1 );
            randIdx = randi( setLen, 1 );
            val = obj.val(randIdx);
        end
        
        function val = genRandom( obj )
            val = rand( 1 ) * ...
                (max( obj.val) - min( obj.val )) + ...
                min( obj.val );
        end
        
    end
    
end
