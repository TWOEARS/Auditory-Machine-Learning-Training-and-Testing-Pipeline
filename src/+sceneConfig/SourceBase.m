classdef SourceBase < matlab.mixin.Copyable & matlab.mixin.Heterogeneous & Parameterized

    %% -----------------------------------------------------------------------------------
    properties
        azimuth;
        distance;
        type;
        data;
        offset;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SourceBase( varargin )
            pds{1} = struct( 'name', 'azimuth', ...
                             'default', sceneConfig.ValGen( 'manual', 0 ), ...
                             'valFun', @(x)(isa(x, 'sceneConfig.ValGen')) );
            pds{2} = struct( 'name', 'distance', ...
                             'default', sceneConfig.ValGen( 'manual', 3 ), ...
                             'valFun', @(x)(isa(x, 'sceneConfig.ValGen')) );
            pds{3} = struct( 'name', 'type', ...
                             'default', 'point', ...
                             'valFun', @(x)(ischar(x) && ...
                                            any(strcmpi(x,{'point','diffuse'})) ) );
            pds{4} = struct( 'name', 'data', ...
                             'default', sceneConfig.NoiseValGen( ...
                                            struct('len',sceneConfig.ValGen('manual',44100))), ...
                             'valFun', @(x)(isa(x, 'sceneConfig.ValGen')) );
            pds{5} = struct( 'name', 'offset', ...
                             'default', sceneConfig.ValGen.empty, ...
                             'valFun', @(x)(isa(x, 'sceneConfig.ValGen')) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function srcInstance = instantiate( obj )
            srcInstance = copy( obj );
            srcInstance.azimuth = obj.azimuth.instantiate();
            srcInstance.distance = obj.distance.instantiate();
            srcInstance.data = obj.data.instantiate();
            srcInstance.offset = obj.offset.instantiate();
        end
        %% -------------------------------------------------------------------------------
        
        function e = isequal( obj1, obj2 )
            e = isequal( obj1.azimuth, obj2.azimuth ) && ...
                isequal( obj1.distance, obj2.distance ) && ...
                isequal( obj1.type, obj2.type ) && ...
                isequal( obj1.data, obj2.data ) && ...
                isequal( obj1.offset, obj2.offset );
        end
        %% -------------------------------------------------------------------------------
                
    end
    
end
