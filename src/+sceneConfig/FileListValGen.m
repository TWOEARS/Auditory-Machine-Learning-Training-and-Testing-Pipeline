classdef FileListValGen < sceneConfig.ValGen

    %%
    methods
        
        function obj = FileListValGen( val )
            if ~iscellstr( val ) && ~ischar( val )
                error( 'FileListValGen requires [cell] array with file name[s] as input.' );
            end
            if ischar( val )
                valGenArgs = {'manual', val};
            elseif numel( val ) == 1
                valGenArgs = {'manual', val{1}};
            else
                valGenArgs = {'set', val};
            end
            obj = obj@sceneConfig.ValGen( valGenArgs{:} );
        end
        
        function e = isequal( obj1, obj2 )
            if ~strcmpi( obj1.type, obj2.type )
                e = false; 
                return; 
            end
            if strcmpi( obj1.type, 'manual' )
                e = isequal( obj1.val, obj2.val ); 
                return; 
            end
            if length( obj1.val ) ~= length( obj2.val )
                e = false;
                return;
            end
            for jj = 1 : length( obj1.val )
                [bp, fn, fe] = fileparts( obj1.val{jj} );
                [~, cp, ~] = fileparts( bp );
                files1{jj} = fullfile( cp, [fn fe] );
                [bp, fn, fe] = fileparts( obj2.val{jj} );
                [~, cp, ~] = fileparts( bp );
                files2{jj} = fullfile( cp, [fn fe] );
            end
            e = isequal( sort( files1 ), sort( files2 ) );
        end
        
    end
    
end
