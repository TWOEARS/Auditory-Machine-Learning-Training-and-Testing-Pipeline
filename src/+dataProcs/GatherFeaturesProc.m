classdef GatherFeaturesProc < core.IdProcInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private, Transient)
        data;
        sceneCfgDataUseRatio = 1;
        prioClass = [];
        inputProc;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = GatherFeaturesProc()
            obj = obj@core.IdProcInterface();
        end
        %% -------------------------------------------------------------------------------

        function connectData( obj, data )
            obj.data = data;
        end
        %% -------------------------------------------------------------------------------

        function setSceneCfgDataUseRatio( obj, sceneCfgDataUseRatio, prioClass )
            obj.sceneCfgDataUseRatio = sceneCfgDataUseRatio;
            if nargin < 3, prioClass = []; end
            obj.prioClass = prioClass;
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            xy = obj.loadInputData( wavFilepath );
            dataFile = obj.data(':',wavFilepath);
            fprintf( '.' );
            if obj.sceneCfgDataUseRatio < 1  &&  ...
                    ~strcmp( obj.prioClass, IdEvalFrame.readEventClass( wavFilepath ) )
                nUsePoints = round( size( xy.x, 1 ) * obj.sceneCfgDataUseRatio );
                useIdxs = randperm( size( xy.x, 1 ) );
                useIdxs(nUsePoints+1:end) = [];
            else
                useIdxs = 1 : size( xy.x, 1 );
            end
            dataFile.x = [dataFile.x; xy.x(useIdxs,:)];
            dataFile.y = [dataFile.y; xy.y(useIdxs)];
%             dataFile.mc = [dataFile.mc; repmat( ii, size( xy.y(useIdxs) ) )];
            fprintf( '.' );
        end
        %% -------------------------------------------------------------------------------
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( obj )
        end
        %% -------------------------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
