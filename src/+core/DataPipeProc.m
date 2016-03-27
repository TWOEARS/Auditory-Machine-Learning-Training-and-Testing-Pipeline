classdef DataPipeProc < handle
    %% identification training data creation pipeline processor
    %
    
    %% --------------------------------------------------------------------
    properties (Access = protected, Transient)
        data;
    end
    properties (SetAccess = protected, Transient)
        dataFileProcessor;
%         inputFileNameBuilder;
        fileListOverlay;
%         precedingFileNeededList;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = DataPipeProc( dataFileProc )
            if ~isa( dataFileProc, 'core.IdProcInterface' )
                error( 'dataFileProc must be of type core.IdProcInterface.' );
            end
            obj.dataFileProcessor = dataFileProc;
%             obj.inputFileNameBuilder = @(inFileName)(inFileName);
        end
        %% ----------------------------------------------------------------

        function init( obj )
            obj.dataFileProcessor.init();
        end
        %% ----------------------------------------------------------------

        function connectData( obj, data )
            obj.data = data;
            obj.fileListOverlay =  true( 1, length( obj.data(:) ) ) ;
%             obj.precedingFileNeededList =  true( 1, length( obj.data(:) ) ) ;
        end
        %% ----------------------------------------------------------------

        function connectToOutputFrom( obj, outputtingProc )
            if ~isa( outputtingProc, 'core.DataPipeProc' )
                error( 'outputtingProc must be of type core.DataPipeProc' );
            end
%             obj.inputFileNameBuilder = outputtingProc.getOutputFileNameBuilder();
%             obj.dataFileProcessor.setExternOutputDependencies( ...
%                 outputtingProc.getOutputDependencies() );
            obj.dataFileProcessor.setInputProc( ...
                outputtingProc.dataFileProcessor.getOutputObject() );
        end
        %% ----------------------------------------------------------------
% 
%         function outFileNameBuilder = getOutputFileNameBuilder( obj )
%             outFileNameBuilder = @(inFileName)(obj.dataFileProcessor.getOutputFileName( inFileName ));
%         end
%         %% ----------------------------------------------------------------
% 
%         function outDeps = getOutputDependencies( obj )
%             outDeps = obj.dataFileProcessor.getOutputDependencies();
%         end
%         %% ----------------------------------------------------------------

        function checkDataFiles( obj, otherOverlay )
            fprintf( '\nChecking file list: %s\n%s\n', ...
                     obj.dataFileProcessor.procName, ...
                     repmat( '=', 1, 20 + numel( obj.dataFileProcessor.procName ) ) );
            if (nargin > 1) && ~isempty( otherOverlay ) && ...
                    (length( otherOverlay ) == length( obj.data(:) ))
                obj.fileListOverlay = otherOverlay;
%                 obj.precedingFileNeededList = otherOverlay;
            else
                obj.fileListOverlay =  true( 1, length( obj.data(:) ) ) ;
%                 obj.precedingFileNeededList =  true( 1, length( obj.data(:) ) ) ;
            end
            datalist = obj.data(:)';
            obj.dataFileProcessor.getSingleProcessCacheAccess();
            for ii = 1 : length( datalist )
                if ~obj.fileListOverlay(ii), continue; end
                dataFile = datalist(ii);
                fprintf( '%s\n', dataFile.wavFileName );
                fileHasBeenProcessed = ...
                    obj.dataFileProcessor.hasFileAlreadyBeenProcessed( dataFile.wavFileName );
                obj.fileListOverlay(ii) = ~fileHasBeenProcessed;
            end
            fprintf( '..' );
            obj.dataFileProcessor.saveCacheDirectory();
            obj.dataFileProcessor.releaseSingleProcessCacheAccess();
            fprintf( ';\n' );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            fprintf( '\nRunning: %s\n%s\n', ...
                     obj.dataFileProcessor.procName, ...
                     repmat( '=', 1, 9 + numel( obj.dataFileProcessor.procName ) ) );
            datalist = obj.data(:);
            datalist = datalist(obj.fileListOverlay);
            for dataFile = datalist(randperm(length(datalist)))'
                fprintf( '%s << %s\n', obj.dataFileProcessor.procName, dataFile.wavFileName );
                obj.dataFileProcessor.processSaveAndGetOutput( dataFile.wavFileName );
                % TODO: semaphore
                fprintf( '\n' );
            end
            obj.dataFileProcessor.saveCacheDirectory();
            fprintf( '..;\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
        
    end
    
end

