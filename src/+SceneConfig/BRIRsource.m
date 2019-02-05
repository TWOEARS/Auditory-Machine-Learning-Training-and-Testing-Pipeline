classdef BRIRsource < SceneConfig.SourceBase & Parameterized

    %% -----------------------------------------------------------------------------------

    properties
        brirFName;
        speakerId;
    end
    %% -----------------------------------------------------------------------------------
    
    properties (SetAccess = protected)
        azimuth; % src-to-head
    end
%% -----------------------------------------------------------------------------------

    methods
        
        function obj = BRIRsource( brirFName, varargin )
            pds{1} = struct( 'name', 'speakerId', ...
                             'default', [], ...
                             'valFun', @(x)(isnumeric(x)) );
            obj = obj@Parameterized( pds );
            obj = obj@SceneConfig.SourceBase( varargin{:} );
            obj.brirFName = strrep( brirFName, '\', '/' );
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            f1SepIdxs = strfind( obj1.brirFName, '/' );
            f2SepIdxs = strfind( obj2.brirFName, '/' );
            e = isequal@SceneConfig.SourceBase( obj1, obj2 ) && ...
                isequal( obj1.speakerId, obj2.speakerId ) && ...
                strcmp( obj1.brirFName(f1SepIdxs(end-1):end), obj2.brirFName(f2SepIdxs(end-1):end) );
        end
        %% -------------------------------------------------------------------------------

        function calcAzimuth( obj, brirHeadOrientIdx )
            if isempty( obj.speakerId )
                sid = 1;
            else
                sid = obj.speakerId;
            end
            brirFile = db.getFile( obj.brirFName );
            srcPosition = sofa.getLoudspeakerPositions(brirFile, sid, 'cartesian');
            listenerPosition = sofa.getListenerPositions(brirFile, 1, 'cartesian');
            brirSrcOrientation = SOFAconvertCoordinates(...
                                srcPosition - listenerPosition, 'cartesian', 'spherical');
            headOrientation = SceneConfig.BRIRsource.getBrirHeadOrientation( ...
                                                            brirFile, brirHeadOrientIdx );
            obj.azimuth = wrapTo180( brirSrcOrientation(1) - headOrientation(1) );
        end
        %% -------------------------------------------------------------------------------
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        function headOrientation = getBrirHeadOrientation( brirFile, brirHeadOrientIdx )
            [~, listenerIdxs] = sofa.getListenerPositions(brirFile, 1, 'cartesian');
            [availableAzimuths, availableElevations] = ...
                                         sofa.getHeadOrientations(brirFile, listenerIdxs);
            % only consider entries with approx. zero elevation angle
            availableAzimuths = availableAzimuths( abs( availableElevations ) < 0.01 );
            availableAzimuths = wrapTo360( availableAzimuths );
            headOrientIdx = round( 1 + brirHeadOrientIdx * (size( availableAzimuths, 1 ) - 1));
            headOrientation = availableAzimuths(headOrientIdx,1);
        end
        %% -------------------------------------------------------------------------------
    end
    %% -----------------------------------------------------------------------------------
    
end
