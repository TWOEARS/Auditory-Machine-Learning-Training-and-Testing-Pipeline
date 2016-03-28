classdef IdProcWrapper < core.IdProcInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        wrappedProcs;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdProcWrapper( wrapProcs, includeWrappedProcsInName )
            obj = obj@core.IdProcInterface();
            if ~iscell( wrapProcs ), wrapProcs = {wrapProcs}; end
            for ii = 1 : numel( wrapProcs )
                if ~isa( wrapProcs{ii}, 'core.IdProcInterface' )
                    error( 'wrapProc must implement core.IdProcInterface.' );
                end
            end
            if nargin < 2, includeWrappedProcsInName = true; end
            if includeWrappedProcsInName
                wpNames = unique( {wrapProcs{:}.procName} );
                for ii = 2 : numel( wpNames ), wpNames{ii} = [wpNames{ii} '-']; end
                obj.procName = [obj.procName '(' wpNames{:} ')'];
            end
            obj.wrappedProcs = wrapProcs;
        end
        %% ----------------------------------------------------------------

        % override of core.IdProcInterface's method
        function setCacheSystemDir( obj, cacheSystemDir, soundDbBaseDir )
            setCacheSystemDir@core.IdProcInterface( obj, cacheSystemDir, soundDbBaseDir );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.setCacheSystemDir( cacheSystemDir, soundDbBaseDir );
            end
        end
        %% -----------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function saveCacheDirectory( obj )
            saveCacheDirectory@core.IdProcInterface( obj );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.saveCacheDirectory();
            end
        end
        %% -----------------------------------------------------------------        

        % override of core.IdProcInterface's method
        function getSingleProcessCacheAccess( obj )
            getSingleProcessCacheAccess@core.IdProcInterface( obj );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.getSingleProcessCacheAccess();
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function releaseSingleProcessCacheAccess( obj )
            releaseSingleProcessCacheAccess@core.IdProcInterface( obj );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.releaseSingleProcessCacheAccess();
            end
        end
        %% -----------------------------------------------------------------

        % override of core.IdProcInterface's method
        function connectIdData( obj, idData )
            connectIdData@core.IdProcInterface( obj, idData );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.connectIdData( idData );
            end
        end
        %% -------------------------------------------------------------------------------

        % override of core.IdProcInterface's method
        function setInputProc( obj, inputProc )
            setInputProc@core.IdProcInterface( obj, [] );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.setInputProc( inputProc );
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of core.IdProcInterface's method
        function outObjs = getOutputObject( obj )
            outObjs = obj.wrappedProcs{:};
        end
        %% -------------------------------------------------------------------------------
        
    end
        
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
                
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
