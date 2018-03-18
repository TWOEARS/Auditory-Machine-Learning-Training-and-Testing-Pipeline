classdef RandomForestTrainer < ModelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        nTrees;
        inBagSamples;
        minLeafSize;
        numPredictorsToSample;
        method;
        predictorSelection;
    end

    %% --------------------------------------------------------------------
    methods (Access = protected)

        function cpObj = copyElement( obj )
            cpObj = copyElement@ModelTrainers.Base( obj );
            if ~isempty( obj.model )
                cpObj.model = obj.model.copy();
            end
        end
        %% ----------------------------------------------------------------
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = RandomForestTrainer( varargin )
            pds{1} = struct( 'name', 'nTrees', ...
                             'default', 50, ...
                             'valFun', @(x)(rem(x,1) == 0 && x > 0) );
            pds{2} = struct( 'name', 'method', ...
                             'default', 'classification', ...
                             'valFun', @(x)(ischar(x) && any(strcmpi(x, ...
                                                                     {'classification',...
                                                                      'regression'}))) );
            pds{3} = struct( 'name', 'minLeafSize', ...
                             'default', 1, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            pds{4} = struct( 'name', 'numPredictorsToSample', ...
                             'default', @(nFeatures)(max( 1, floor( sqrt( nFeatures ) ) )), ...
                             'valFun', @(x)(rem(x(1),1) == 0 && x(1) > 0) );
            pds{5} = struct( 'name', 'inBagSamples', ...
                             'default', inf, ...
                             'valFun', @(x)((rem(x,1)==0 || isinf(x)) && x > 0) );
            pds{6} = struct( 'name', 'predictorSelection', ...
                             'default', 'allsplits', ...
                             'valFun', @(x)(ischar(x) && any(strcmpi(x, ...
                                                                     {'curvature',...
                                                                      'allsplits',...
                                                                      'interaction-curvature'}))) );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.Base( varargin{:} );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y, iw )
            obj.model = Models.RandomForestModel();
            inBagFraction = min( 1, obj.inBagSamples / size( x, 1 ) );
            fprintf( '\nTreeBagger %s training with nTrees=%d, minLeafSize=%d, sampleFraction=%f, splitFeatures=%d\n\tsize(x) = %dx%d\n\n', ...
                                        obj.method, obj.nTrees, obj.minLeafSize, inBagFraction, obj.numPredictorsToSample( size( x, 2 ) ), size(x,1), size(x,2) );
            rfModel = TreeBagger( obj.nTrees, x, y, 'W', iw, ...
                                  'Method', obj.method, ...
                                  'MinLeafSize', obj.minLeafSize, ...
                                  'NumPredictorsToSample', obj.numPredictorsToSample( size( x, 2 ) ), ...
                                  'InBagFraction', inBagFraction, ...
                                  'PredictorSelection', obj.predictorSelection );
            obj.model.model = compact( rfModel );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.model;
        end
        %% ----------------------------------------------------------------
        
    end
    
end