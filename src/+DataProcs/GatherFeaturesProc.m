classdef GatherFeaturesProc < Core.IdProcInterface
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private, Transient)
        nSamplesPerSceneInstance = 1;
        nSamplesPerTargetSceneInstance = 1;
        dataSelector;
        selectTargetLabel = [];
        loadBlockAnnotations = false;
        prioClass = [];
        dataConverter;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = GatherFeaturesProc( loadBlockAnnotations, dataConverter )
            obj = obj@Core.IdProcInterface();
            if nargin >= 1
                obj.loadBlockAnnotations = loadBlockAnnotations;
            end
            if nargin < 2 || isempty( dataConverter )
                dataConverter = @single;
            end
            obj.dataConverter = dataConverter;
        end
        %% -------------------------------------------------------------------------------

        function setNsamplesPerSceneInstance( obj, nSamplesPerSceneInstance, dataSelector, ...
                                               nSamplesPerTargetSceneInstance, selectTargetLabel )
            obj.nSamplesPerSceneInstance = nSamplesPerSceneInstance;
            if nargin < 3, dataSelector = DataSelectors.IgnorantSelector(); end
            if nargin < 4, nSamplesPerTargetSceneInstance = 1; end
            if nargin < 5, selectTargetLabel = []; end
            obj.dataSelector = dataSelector;
            obj.nSamplesPerTargetSceneInstance = nSamplesPerTargetSceneInstance;
            obj.selectTargetLabel = selectTargetLabel;
        end
        %% -------------------------------------------------------------------------------

        function process( obj, wavFilepath )
            obj.setLoadSemaphore = false;
            obj.secondCfgCheck = false;
            if obj.loadBlockAnnotations
                xy = obj.loadInputData( wavFilepath, 'x', 'y', 'ysi', 'a' );
                xy.blockAnnotations = Core.IdentTrainPipeDataElem.addPPtoBas( xy.a, xy.y );
                xy = rmfield( xy, 'a' );
                sceneCfgDeps = obj.inputProc.getOutputDependencies();
                while ~(isstruct( sceneCfgDeps ) && isfield( sceneCfgDeps, 'sceneCfg' ) )
                    sceneCfgDeps = sceneCfgDeps.preceding;
                end
                isNotPointSource = @(x)(isa( x, 'SceneConfig.DiffuseSource' ) || isa( x, 'SceneConfig.DirectInputSource' ) );
				npssc = sum( arrayfun( @(a)(~isNotPointSource), sceneCfgDeps.sceneCfg.sources ) );
                [xy.blockAnnotations(:).nPointSrcsSceneConfig] = deal( npssc );
            else
                xy = obj.loadInputData( wavFilepath, 'x', 'y', 'ysi' );
            end
            obj.inputProc.inputProc.sceneId = obj.sceneId;
            obj.inputProc.inputProc.foldId = obj.foldId;
            obj.inputProc.inputProc.secondCfgCheck = false;
            inDataFilepath = obj.inputProc.inputProc.getOutputFilepath( wavFilepath );
            dataFile = obj.idData(wavFilepath);
            fprintf( '.' );
            if ~isempty( obj.selectTargetLabel ) && any( xy.y == obj.selectTargetLabel )
                nUsePoints = min( [size( xy.x, 1 ), obj.nSamplesPerTargetSceneInstance] );
            else
                nUsePoints = min( [size( xy.x, 1 ), obj.nSamplesPerSceneInstance] );
            end
            obj.dataSelector.connectData( xy );
            useIdxs = obj.dataSelector.getDataSelection( 1:size( xy.x, 1 ), nUsePoints );
            dataFile.x = [dataFile.x; obj.dataConverter( xy.x(useIdxs,:) )];
            dataFile.y = [dataFile.y; obj.dataConverter( xy.y(useIdxs,:) )];
            dataFile.ysi = [dataFile.ysi; xy.ysi(useIdxs)'];
            dataFile.bIdxs = [dataFile.bIdxs; int32( xy.bIdxs(useIdxs)' )];
            dataFile.bacfIdxs = [dataFile.bacfIdxs; ...
                  repmat( int32( numel(dataFile.blockAnnotsCacheFile ) + 1 ), sum(useIdxs), 1 )];
            dataFile.blockAnnotsCacheFile = [dataFile.blockAnnotsCacheFile; {inDataFilepath}];
            if obj.loadBlockAnnotations
                dataFile.blockAnnotations = [dataFile.blockAnnotations; xy.blockAnnotations(useIdxs)];
            end
            obj.dataSelector.connectData( [] );
            fprintf( ':%d.', size( dataFile.x, 1 ) );
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [out, outFilepath] = loadProcessedData( ~, ~ ) 
            out = [];
            outFilepath = '';
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function outFilepath = getOutputFilepath( ~, ~ )
            outFilepath = [];
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function [fileProcessed,cacheDir] = hasFileAlreadyBeenProcessed( ~, ~ )
            fileProcessed = false;
            cacheDir = [];
        end
        %% -------------------------------------------------------------------------------
       
        % override of Core.IdProcInterface's method
        function currentFolder = getCurrentFolder( ~ )
            currentFolder = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function out = save( ~, ~, ~ )
            out = [];
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function setCacheSystemDir( ~, ~, ~, ~ )
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function saveCacheDirectory( ~ )
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function loadCacheDirectory( ~ )
        end
        %% -------------------------------------------------------------------------------

        % override of Core.IdProcInterface's method
        function getSingleProcessCacheAccess( ~ )
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function releaseSingleProcessCacheAccess( ~ )
        end
        %% -------------------------------------------------------------------------------
        
        % override of Core.IdProcInterface's method
        function delete( obj )
            removefilesemaphore( obj.outFileSema );
        end
        %% -------------------------------------------------------------------------------
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( ~ )
            outputDeps.gatherDeps = [];
        end
        %% -------------------------------------------------------------------------------

        function out = getOutput( ~, ~ )
            out = [];
        end
        %% -------------------------------------------------------------------------------
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end
