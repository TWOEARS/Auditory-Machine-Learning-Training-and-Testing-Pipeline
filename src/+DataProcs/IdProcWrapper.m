classdef IdProcWrapper < Core.IdProcInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        wrappedProcs;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdProcWrapper( wrapProcs, includeWrappedProcsInName )
            obj = obj@Core.IdProcInterface();
            if ~iscell( wrapProcs ), wrapProcs = {wrapProcs}; end
            for ii = 1 : numel( wrapProcs )
                if ~isa( wrapProcs{ii}, 'Core.IdProcInterface' )
                    error( 'wrapProc must implement Core.IdProcInterface.' );
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

        % override of Core.IdProcInterface's method
        function setCacheSystemDir( obj, cacheSystemDir, nPathLevelsForCacheName, cacheDirectoryDirSuppl )
            setCacheSystemDir@Core.IdProcInterface( obj, cacheSystemDir, nPathLevelsForCacheName, cacheDirectoryDirSuppl );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.setCacheSystemDir( cacheSystemDir, nPathLevelsForCacheName, cacheDirectoryDirSuppl );
            end
        end
        %% -----------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function saveCacheDirectory( obj )
            saveCacheDirectory@Core.IdProcInterface( obj );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.saveCacheDirectory();
            end
        end
        %% -----------------------------------------------------------------        
        
        % override of Core.IdProcInterface's method
        function loadCacheDirectory( obj )
            loadCacheDirectory@Core.IdProcInterface( obj );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.loadCacheDirectory();
            end
        end
        %% -----------------------------------------------------------------        

        % override of Core.IdProcInterface's method
        function getSingleProcessCacheAccess( obj )
            getSingleProcessCacheAccess@Core.IdProcInterface( obj );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.getSingleProcessCacheAccess();
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function releaseSingleProcessCacheAccess( obj )
            releaseSingleProcessCacheAccess@Core.IdProcInterface( obj );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.releaseSingleProcessCacheAccess();
            end
        end
        %% -----------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function connectIdData( obj, idData )
            connectIdData@Core.IdProcInterface( obj, idData );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.connectIdData( idData );
            end
        end
        %% -----------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function init( obj )
            init@Core.IdProcInterface( obj );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.init();
            end
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function setInputProc( obj, inputProc )
            setInputProc@Core.IdProcInterface( obj, inputProc );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.setInputProc( inputProc );
            end
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function outObjs = getOutputObject( obj )
            outObjs = obj.wrappedProcs{:};
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function setDirectCacheSave( obj, saveImmediately )
            setDirectCacheSave@Core.IdProcInterface( obj, saveImmediately );
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.setDirectCacheSave( saveImmediately );
            end
        end            
        %% -------------------------------------------------------------------------------
        
    end
        
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            for ii = 1 : numel( obj.wrappedProcs )
                outDepName = sprintf( 'wrappedProc%d', ii );
                outputDeps.(outDepName) = obj.wrappedProcs{ii}.getOutputDependencies;
            end
        end
        %% ----------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function newPCFN = overridableSetPCFN( obj, newPCFN )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.procCacheFolderNames = newPCFN;
            end
            newPCFN = overridableSetPCFN@Core.IdProcInterface( obj, newPCFN );
        end
        %% ----------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function newScnId = overridableSetScnId( obj, newScnId )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.sceneId = newScnId;
            end
            newScnId = overridableSetScnId@Core.IdProcInterface( obj, newScnId );
        end
        %% ----------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function newFoldId = overridableSetFoldId( obj, newFoldId )
            for ii = 1 : numel( obj.wrappedProcs )
                obj.wrappedProcs{ii}.foldId = newFoldId;
            end
            newFoldId = overridableSetFoldId@Core.IdProcInterface( obj, newFoldId );
        end
        %% ----------------------------------------------------------------
                
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
