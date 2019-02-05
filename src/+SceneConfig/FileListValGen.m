classdef FileListValGen < SceneConfig.ValGen

    %% ---------------------------------------------------------------------------------------------
    properties
        filesepsAreUnix = false; % for compatibility with saved FileListValGens
        eqTestFlistPrep = {};
    end
    
    %% ---------------------------------------------------------------------------------------------
    methods
        
        function obj = FileListValGen( val )
            if ~iscellstr( val ) && ~ischar( val )
                error( 'FileListValGen requires [cell] array with file name[s] as input.' );
            end
            val = strrep( val, '\', '/' );
            if ischar( val )
                valGenArgs = {'manual', val};
            elseif numel( val ) == 1
                valGenArgs = {'manual', val{1}};
            else
                valGenArgs = {'set', val};
            end
            obj = obj@SceneConfig.ValGen( valGenArgs{:} );
            obj.filesepsAreUnix = true;
            obj.prepEqTestFlist();
        end
        %% -----------------------------------------------------------------------------------------
        
        function obj = prepEqTestFlist( obj )
            if strcmpi( obj.type, 'set' )
                fSepIdxs = strfind( obj.val, '/' );
                obj.eqTestFlistPrep = cellfun( ...
                                    @(f,idx)( f(idx(end-2):end) ), obj.val, fSepIdxs, ...
                                                                 'UniformOutput', false );
                obj.eqTestFlistPrep = sort( obj.eqTestFlistPrep );
                obj.eqTestFlistPrep = DataHash_( obj.eqTestFlistPrep, struct( 'Method', {'SHA-512'} ) );
            else
                obj.eqTestFlistPrep = obj.val;
            end
        end
        %% -----------------------------------------------------------------------------------------

        function svCmpCfg = getSaveCompareConfig( obj )
            svCmpCfg = obj.copy();
            if isempty( svCmpCfg.eqTestFlistPrep ) && ~isempty( svCmpCfg.val )
                if ~svCmpCfg.filesepsAreUnix
                    svCmpCfg.val = strrep( svCmpCfg.val, '\', '/' );
                    svCmpCfg.filesepsAreUnix = true;
                end
                obj1svCmpCfg.prepEqTestFlist();
            end
            if ~strcmpi( svCmpCfg.type, 'manual' )
                svCmpCfg.val = [];
            end
        end
        %% -------------------------------------------------------------------------------
        
        function s = saveobj( obj )
            if ~any( isa( obj, 'SceneConfig.FileListValGen' ) ) % add all subtypes
                error( 'Subclasses must implement saveobj too. When done add type to condition.' );
            end
            s = obj.getSaveCompareConfig();
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            if ~strcmpi( obj1.type, obj2.type )
                e = false; 
                return; 
            end
            if strcmpi( obj1.type, 'manual' )
                e = isequal( obj1.val, obj2.val ); 
                return; 
            end
            if isempty( obj1.eqTestFlistPrep ) && ~isempty( obj1.val )
                if ~obj1.filesepsAreUnix
                    obj1.val = strrep( obj1.val, '\', '/' );
                    obj1.filesepsAreUnix = true;
                end
                obj1.prepEqTestFlist();
            end
            if isempty( obj2.eqTestFlistPrep )&& ~isempty( obj2.val )
                if ~obj2.filesepsAreUnix
                    obj2.val = strrep( obj2.val, '\', '/' );
                    obj2.filesepsAreUnix = true;
                end
                obj2.prepEqTestFlist();
            end
            e = isequal( obj1.eqTestFlistPrep, obj2.eqTestFlistPrep );
        end
        %% -----------------------------------------------------------------------------------------
        
    end
    
    %% ---------------------------------------------------------------------------------------------
    methods(Static)
        
        function obj = loadobj( s )
            if isstruct( s )
                obj = SceneConfig.FileListValGen( 'tmp' );
                obj.val = [];
                obj.eqTestFlistPrep = s.eqTestFlistPrep;
                obj.filesepsAreUnix = s.filesepsAreUnix;
            else
                obj = s;
                if ~strcmpi( obj.type, 'manual' )
                    obj.val = [];
                end
            end
        end
        %% -----------------------------------------------------------------------------------------

    end

end
