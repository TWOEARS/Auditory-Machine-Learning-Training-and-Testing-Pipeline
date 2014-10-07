classdef WallsValGen < ValGen

    %%
    methods
        
        function obj = WallsValGen( val )
            if ~( ...
                    isfield( val, 'front' ) && isa( val.front, 'ValGen' ) && ...
                    isfield( val, 'back' ) && isa( val.back, 'ValGen' ) && ...
                    isfield( val, 'right' ) && isa( val.right, 'ValGen' ) && ...
                    isfield( val, 'left' ) && isa( val.left, 'ValGen' ) && ...
                    isfield( val, 'height' ) && isa( val.height, 'ValGen' ) && ...
                    isfield( val, 'rt60' ) && isa( val.rt60, 'ValGen' ) )
                error( 'val does not provide all needed fields' );
            end
            obj = obj@ValGen( 'manual', val );
            obj.type = 'specific';
        end
        
        function val = genVal( obj )
            wall = simulator.Wall();
            wall.vertices = [obj.val.front.genVal(), obj.val.right.genVal();...
                             obj.val.front.genVal(), obj.val.left.genVal();...
                             obj.val.back.genVal(), obj.val.left.genVal();...
                             obj.val.back.genVal(), obj.val.right.genVal()];
            roomheight = obj.val.height.genVal();
            RT60 = obj.val.rt60.genVal();
            walls(1:4) = wallObj.createUniformPrism( roomheight, '2D', RT60 );
            val = walls;
        end
        
    end
    
    %%
    methods (Access = protected)
        
        
    end
    
end
