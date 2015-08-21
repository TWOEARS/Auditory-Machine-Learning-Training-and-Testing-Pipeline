classdef FileListValGen < dataProcs.ValGen

    %%
    methods
        
        function obj = FileListValGen( val )
            if ~iscellstr( val )
                error( 'FileListValGen requires cell array of file names as input.' );
            end
            obj = obj@dataProcs.ValGen( 'set', val );
        end
        
        function e = isequal( obj, obj2 )
            if length( obj.val ) ~= length( obj2.val )
                e = false;
                return;
            end
            for jj = 1 : length( obj.val )
                [bp, fn, fe] = fileparts( obj.val{jj} );
                [~, cp, ~] = fileparts( bp );
                files1{jj} = fullfile( cp, [fn fe] );
                [bp, fn, fe] = fileparts( obj2.val{jj} );
                [~, cp, ~] = fileparts( bp );
                files2{jj} = fullfile( cp, [fn fe] );
            end
            e = isequaln( sort( files1 ), sort( files2 ) );
        end
        
    end
    
end
