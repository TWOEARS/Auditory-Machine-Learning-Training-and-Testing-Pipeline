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
            brirSofa = SOFAload( db.getFile( obj.brirFName ), 'nodata' );
            if isempty( obj.speakerId )
                sid = 1;
            else
                sid = obj.speakerId;
            end
            if size( brirSofa.SourcePosition, 1 ) < sid
                assert( size( brirSofa.EmitterPosition, 1 ) >= sid );
                srcPos = brirSofa.EmitterPosition(sid,:);
            elseif size( brirSofa.EmitterPosition, 1 ) < sid
                assert( size( brirSofa.SourcePosition, 1 ) >= sid );
                srcPos = brirSofa.SourcePosition(sid,:);
            else
                if any( brirSofa.SourcePosition(sid,:) ~= brirSofa.EmitterPosition(sid,:) )
                    % SourcePosition and EmitterPosition are different...
                    if all( brirSofa.SourcePosition(sid,:) == 0 )
                        % SourcePosition is unset
                        srcPos = brirSofa.EmitterPosition(sid,:);
                    elseif all( brirSofa.EmitterPosition(sid,:) == 0 )
                        % EmitterPosition is unset
                        srcPos = brirSofa.SourcePosition(sid,:);
                    else
                        error( 'Now I don''t know how to decide any more. This should not happen.' );
                    end
                else
                    srcPos = brirSofa.SourcePosition(sid,:);
                end
            end
            brirSrcOrientation = SOFAconvertCoordinates( srcPos - brirSofa.ListenerPosition, ...
                                                                'cartesian','spherical' );
            headOrientation = SceneConfig.BRIRsource.getBrirHeadOrientation( ...
                                                            brirSofa, brirHeadOrientIdx );
            obj.azimuth = wrapTo180( brirSrcOrientation(1) - headOrientation(1) );
        end
        %% -------------------------------------------------------------------------------
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        function headOrientation = getBrirHeadOrientation( brirSofa, brirHeadOrientIdx )
            headOrientIdx = round( 1 + brirHeadOrientIdx * (size( brirSofa.ListenerView, 1 ) - 1));
            if (strcmpi(brirSofa.ListenerView_Type, 'cartesian'))
                headOrientation = SOFAconvertCoordinates( ...
                    brirSofa.ListenerView(headOrientIdx,:),'cartesian','spherical' );
            else
                headOrientation = brirSofa.ListenerView(headOrientIdx,1);
            end
        end
        %% -------------------------------------------------------------------------------
    end
    %% -----------------------------------------------------------------------------------
    
end
