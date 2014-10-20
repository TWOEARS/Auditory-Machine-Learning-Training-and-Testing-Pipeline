classdef (Abstract) IdWp2ProcInterface < IdProcInterface
    %% responsible for transforming wp1 files into wp2 acoustic cues files
    %   

    %%---------------------------------------------------------------------
    properties (SetAccess = private, Transient)
        buildWp1FileName;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdWp2ProcInterface()
            obj = obj@IdProcInterface();
        end
        
        %%-----------------------------------------------------------------
            
        function setWp1FileNameBuilder( obj, wp1FileNameBuilder )
            obj.buildWp1FileName = wp1FileNameBuilder;
        end
        
        %%-----------------------------------------------------------------

        function run( obj )
            fprintf( 'wp2 processing' );
            for trainFile = obj.data(:)'
                wp2FileName = obj.buildProcFileName( trainFile.wavFileName );
                fprintf( '\n.%s', wp2FileName );
                if exist( wp2FileName, 'file' ), continue; end
                wp1mat = load( obj.buildWp1FileName( trainFile.wavFileName ) );
                wp2data = obj.makeWp2Data( wp1mat.earSignals );
                save( wp2FileName, 'wp2data' );
            end
            fprintf( ';\n' );
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    %%---------------------------------------------------------------------
    methods (Abstract)
        init( obj, fs, wp2Requests )
    end
    methods (Abstract, Access = protected)
        wp2data = makeWp2Data( obj, earSignals )
    end
    
end

