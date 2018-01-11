classdef MultiFileListValGen < SceneConfig.ValGen

    %%
    properties
        useFileListId = 1;
    end
    
    %%
    methods
        
        function obj = MultiFileListValGen( val )
            if ~iscell( val ) || any( ~cellfun( @iscellstr, val ) && ~cellfun( @ischar, val ) )
                error( 'MultiFileListValGen requires cell of [cell] array(s) with file name[s] as input.' );
            end
            for ii = 1 : numel( val )
                fileListValGens{ii} = SceneConfig.FileListValGen( val{ii} ); %#ok<AGROW>
            end
            obj = obj@SceneConfig.ValGen( 'set', fileListValGens );
        end

        % override of ValGen's method
        function instance = instantiate( obj )
            instance = instantiate@SceneConfig.ValGen( obj );
            instance.val = obj.val{obj.useFileListId};
        end

        function e = isequal( obj1, obj2 )
            e = all( cellfun( @isequal, obj1.val, obj2.val ) );
        end
        
    end
    
end
