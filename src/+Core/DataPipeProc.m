classdef DataPipeProc < handle
    %% identification training data creation pipeline processor
    %
    
    %% --------------------------------------------------------------------
    properties (Access = protected, Transient)
        data;
    end
    properties (SetAccess = protected, Transient)
        dataFileProcessor;
        fileListOverlay;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
        
        function b = doEarlyHasProcessedStop( bSet, newValue )
            persistent dehps;
            if isempty( dehps )
                dehps = false;
            end
            if nargin > 0  &&  bSet
                dehps = newValue;
            end
            b = dehps;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = DataPipeProc( dataFileProc )
            if ~isa( dataFileProc, 'Core.IdProcInterface' )
                error( 'dataFileProc must be of type Core.IdProcInterface.' );
            end
            obj.dataFileProcessor = dataFileProc;
        end
        %% ----------------------------------------------------------------

        function init( obj )
            obj.dataFileProcessor.init();
        end
        %% ----------------------------------------------------------------

        function connectData( obj, data )
            obj.data = data;
            obj.fileListOverlay =  true( 1, length( obj.data(:) ) ) ;
        end
        %% ----------------------------------------------------------------

        function connectToOutputFrom( obj, outputtingProc )
            if ~isa( outputtingProc, 'Core.DataPipeProc' )
                error( 'outputtingProc must be of type Core.DataPipeProc' );
            end
            obj.dataFileProcessor.setInputProc( ...
                outputtingProc.dataFileProcessor.getOutputObject() );
        end
        %% ----------------------------------------------------------------

        function cacheDirs = checkDataFiles( obj, otherOverlay )
            fprintf( '\nChecking file list: %s\n%s\n', ...
                     obj.dataFileProcessor.procName, ...
                     repmat( '=', 1, 20 + numel( obj.dataFileProcessor.procName ) ) );
            if (nargin > 1) && ~isempty( otherOverlay ) && ...
                    (length( otherOverlay ) == length( obj.data(:) ))
                obj.fileListOverlay = otherOverlay;
            else
                obj.fileListOverlay =  true( 1, length( obj.data(:) ) ) ;
            end
            datalist = obj.data(:)';
            obj.dataFileProcessor.setDirectCacheSave( false );
            foldsProcessed = {};
            for ii = 1 : length( datalist )
                if ~obj.fileListOverlay(ii), continue; end
                dataFile = datalist(ii);
                fprintf( '%s\n', dataFile.fileName );
                isFirstCheckInFold = obj.determineWhetherFirstFileInFold( foldsProcessed, dataFile );
                if isFirstCheckInFold % with the first file in a fold, caches often update
                    % load cache before restricting access, because it takes long
                    obj.dataFileProcessor.loadCacheDirectory();
                    obj.dataFileProcessor.getSingleProcessCacheAccess();
                    Core.DataPipeProc.doEarlyHasProcessedStop( true, false );
                    foldsProcessed = uniqueHandles( [foldsProcessed, dataFile.containedIn] ); 
                end
                if nargout > 0 && ~exist( 'cacheDirs', 'var' )
                    [fileHasBeenProcessed,cacheDirs] = ...
                        obj.dataFileProcessor.hasFileAlreadyBeenProcessed( dataFile.fileName );
                else
                    fileHasBeenProcessed = ...
                        obj.dataFileProcessor.hasFileAlreadyBeenProcessed( dataFile.fileName );
                end
                if isFirstCheckInFold
                    Core.DataPipeProc.doEarlyHasProcessedStop( true, true );
                    obj.dataFileProcessor.saveCacheDirectory();
                    obj.dataFileProcessor.releaseSingleProcessCacheAccess();
                end
                obj.fileListOverlay(ii) = ~fileHasBeenProcessed;
            end
            fprintf( '..' );
            obj.dataFileProcessor.saveCacheDirectory();
            obj.dataFileProcessor.setDirectCacheSave( true );
            fprintf( ';\n' );
        end
        %% ----------------------------------------------------------------
        
        function isFirstFileInFold = determineWhetherFirstFileInFold( obj, foldsProcessed, dataFile )
            isFirstFileInFold = true;
            for jj = 1 : numel( dataFile.containedIn )
                for kk = 1 : numel( foldsProcessed )
                    if dataFile.containedIn{jj} == foldsProcessed{kk}
                        isFirstFileInFold = false;
                        break;
                    end
                end
                if isFirstFileInFold
                    break;
                end
            end
        end
        %% ----------------------------------------------------------------

        function run( obj, varargin )
            ip = inputParser;
            ip.addOptional( 'debug', false );
            ip.parse( varargin{:} );
            errs = {};
            fprintf( '\nRunning: %s\n%s\n', ...
                     obj.dataFileProcessor.procName, ...
                     repmat( '=', 1, 9 + numel( obj.dataFileProcessor.procName ) ) );
            datalist = obj.data(:)';
            datalist = datalist(obj.fileListOverlay);
            ndf = numel( datalist );
            dfii = 1;
            foldsProcessed = {};
            for dataFile = datalist(randperm(length(datalist)))'
                isFirstRunInFold = obj.determineWhetherFirstFileInFold( foldsProcessed, dataFile );
                if isFirstRunInFold % with the first file in each fold, caches of wrapped procs often update
                    obj.dataFileProcessor.getSingleProcessCacheAccess();
                    obj.dataFileProcessor.setDirectCacheSave( false );
                    foldsProcessed = uniqueHandles( [foldsProcessed, dataFile.containedIn] ); 
                end
                fprintf( '%s << (%d/%d) -- %s\n', ...
                           obj.dataFileProcessor.procName, dfii, ndf, dataFile.fileName );
                if ~ip.Results.debug
                    try
                        obj.dataFileProcessor.processSaveAndGetOutput( dataFile.fileName );
                    catch err
                        if any( strcmpi( err.identifier, ...
                                {'MATLAB:load:couldNotReadFile', ...
                                'MATLAB:load:unableToReadMatFile'} ...
                                ) )
                            errs{end+1} = err;
                            warning( err.message );
                        elseif any( strcmpi( err.identifier, ...
                                {'AMLTTP:dataprocs:cacheFileCorrupt'} ...
                                ) )
                            delete( err.message ); % err.msg contains corrupt cache file name
                            erpl.message = ['deleted corrupt cache file: ' err.message];
                            errs{end+1} = erpl;
                        else
                            rethrow( err );
                        end
                    end
                else
                    obj.dataFileProcessor.processSaveAndGetOutput( dataFile.fileName );
                end
                if isFirstRunInFold
                    obj.dataFileProcessor.saveCacheDirectory();
                    obj.dataFileProcessor.setDirectCacheSave( true );
                    obj.dataFileProcessor.releaseSingleProcessCacheAccess();
                end
                dfii = dfii + 1;
%                 fprintf( '\n' );
%                 freemem = memReport() % for debugging
%                 fprintf( '\n' );
            end
            obj.dataFileProcessor.saveCacheDirectory();
            fprintf( '..;\n' );
            if numel( errs ) > 0
                cellfun(@(c)(warning(c.message)), errs);
                error( 'AMLTTP:dataprocs:fileErrors', ...
                       'errors occured with the %s dataPipeProc filehandling', ...
                       obj.dataFileProcessor.procName );
            end
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
        
    end
    
end

