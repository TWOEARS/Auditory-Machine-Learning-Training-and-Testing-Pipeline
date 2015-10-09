classdef GatherFeaturesProc < handle
    %% 
    %
    
    %% --------------------------------------------------------------------
    properties (Access = protected, Transient)
        data;
        inputFileNameBuilder;
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

        function connectToOutputFrom( obj, outputtingProc )
            if ~isa( outputtingProc, 'core.DataPipeProc' )
                error( 'outputtingProc must be of type core.DataPipeProc' );
            end
            obj.inputFileNameBuilder = outputtingProc.getOutputFileNameBuilder();
        end
        %% ----------------------------------------------------------------

        function run( obj )
            fprintf( '\nRunning: GatherFeaturesProc\n==========================================\n' );
            for dataFile = obj.data(:)'
                fprintf( '.%s ', dataFile.wavFileName );
                inFileName = obj.inputFileNameBuilder( dataFile.wavFileName );
                in = load( inFileName );
                for ii = 1 : numel( in.singleConfFiles )
                    xy = load( in.singleConfFiles{ii} );
                    dataFile.x = [dataFile.x; xy.x];
                    dataFile.y = [dataFile.y; xy.y];
                    fprintf( '.' );
                end
                fprintf( ';\n' );
            end
            fprintf( ';\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end

