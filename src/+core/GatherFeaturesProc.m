classdef GatherFeaturesProc < handle
    %% 
    %
    
    %% --------------------------------------------------------------------
    properties (Access = protected, Transient)
        data;
        inputFileNameBuilder;
        confDataUseRatio = 1;
        prioClass = [];
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = GatherFeaturesProc()
            obj.inputFileNameBuilder = @(inFileName)(inFileName);
        end
        %% ----------------------------------------------------------------

        function connectData( obj, data )
            obj.data = data;
        end
        %% ----------------------------------------------------------------

        function setConfDataUseRatio( obj, confDataUseRatio, prioClass )
            obj.confDataUseRatio = confDataUseRatio;
            if nargin < 3, prioClass = []; end
            obj.prioClass = prioClass;
        end
        %% ----------------------------------------------------------------

        function connectToOutputFrom( obj, outputtingProc )
            if ~isa( outputtingProc, 'core.DataPipeProc' )
                error( 'outputtingProc must be of type core.DataPipeProc' );
            end
            obj.inputFileNameBuilder = outputtingProc.getOutputFileNameBuilder();
        end
        %% ----------------------------------------------------------------

        function run( obj )
            deletedDirFiles = false;
            fprintf( '\nRunning: GatherFeaturesProc\n==========================================\n' );
            for dataFile = obj.data(:)'
                fprintf( '.%s ', dataFile.wavFileName );
                inFileName = obj.inputFileNameBuilder( dataFile.wavFileName );
                try
                    in = load( inFileName, 'singleConfFiles' );
                catch err
                    if strcmp( err.identifier, 'MATLAB:load:couldNotReadFile' ) ...
                            && deletedDirFiles
                        fprintf( ';\n' );
                        continue; 
                    else
                        rethrow( err );
                    end
                end
                dataFile.x = [];
                dataFile.y = [];
                for ii = 1 : numel( in.singleConfFiles )
                    try
                        xy = load( in.singleConfFiles{ii} );
                    catch err
                        if strcmp( err.identifier, 'MATLAB:load:couldNotReadFile' )
                            fprintf( '\n%s seems corrupt.\n', ...
                                inFileName );
                            choice = input( ...
                                ['Choose: [q]uit, [d]elete and quit, '...
                                 'delete and [c]ontinue, '...
                                 'delete all in directory and qui[t], '...
                                 'delete [a]ll in directory and continue'], 's' );
                            switch choice
                                case 'q'
                                    rethrow( err );
                                case 'd'
                                    delete( inFileName );
                                    rethrow( err );
                                case 'c'
                                    delete( inFileName );
                                    continue;
                                case 't'
                                    inFileDir = fileparts( inFileName );
                                    delete( [inFileDir filesep '*.wav.*'] );
                                    rethrow( err );
                                case 'a'
                                    inFileDir = fileparts( inFileName );
                                    delete( [inFileDir filesep '*.wav.*'] );
                                    deletedDirFiles = true;
                                    break;
                                otherwise
                                    rethrow( err );
                            end
                        end
                    end
                    if obj.confDataUseRatio < 1  &&  ...
                       ~strcmp( obj.prioClass, ...
                                IdEvalFrame.readEventClass( dataFile.wavFileName ) )
                        nUsePoints = round( numel( xy.y ) * obj.confDataUseRatio );
                        useIdxs = randperm( numel( xy.y ) );
                        useIdxs(nUsePoints+1:end) = [];
                    else
                        useIdxs = 1 : numel( xy.y );
                    end
                    dataFile.x = [dataFile.x; xy.x(useIdxs,:)];
                    dataFile.y = [dataFile.y; xy.y(useIdxs)];
                    fprintf( '.' );
                end
                fprintf( ';\n' );
            end
            fprintf( ';\n' );
            if deletedDirFiles
                rethrow( err );
            end
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end

