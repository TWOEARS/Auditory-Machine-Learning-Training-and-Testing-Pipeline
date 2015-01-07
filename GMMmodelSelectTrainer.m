classdef GMMmodelSelectTrainer < IdTrainerInterface & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (Access = private)
        cvTrainer;
        coreTrainer;
        fullSetModel;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = GMMmodelSelectTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{3} = struct( 'name', 'comp', ...
                             'default', [1 2 3 4], ...
                             'valFun', @(x)(floor(x)==x) );
            pds{4} = struct( 'name', 'cvFolds', ...
                              'default', 4, ...
                              'valFun', @(x)(rem(x,1) == 0 && x >= 0) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
        function run( obj )
            obj.buildModel();
        end
        %% ----------------------------------------------------------------
        
        function buildModel( obj, ~, ~ )
            verboseFprintf( obj, '\nRun on full trainSet...\n' );
            obj.coreTrainer = GmmNetTrainer( ...
                'performanceMeasure', obj.parameters.performanceMeasure, ...
                'maxDataSize', obj.parameters.maxDataSize );
            obj.coreTrainer.setData( obj.trainSet, obj.testSet );
            obj.coreTrainer.setPositiveClass( obj.positiveClass );
            obj.coreTrainer.run();
            obj.fullSetModel = obj.coreTrainer.getModel();
            comps = obj.fullSetModel.model.comp;
            verboseFprintf( obj, '\nRun cv to determine best number of components...\n' );
            obj.coreTrainer.setParameters( false, 'comp', comps );
            obj.cvTrainer = CVtrainer( obj.coreTrainer );
            obj.cvTrainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.cvTrainer.setPositiveClass( obj.positiveClass );
            obj.cvTrainer.setData( obj.trainSet, obj.testSet );
            obj.cvTrainer.setNumberOfFolds( obj.parameters.cvFolds );
            obj.cvTrainer.run();
            cvModels = obj.cvTrainer.models;
            verboseFprintf( obj, 'Calculate Performance for all values of components...\n' );
            lPerfs = zeros( numel( comps ), numel( cvModels ) );
            coefs = zeros( numel( comps ), numel( cvModels ), ...
                           obj.fullSetModel.model.dim(1) );
            coefsRel = zeros( numel(comps ), numel( cvModels ), ...
                           obj.fullSetModel.model.dim(1) );
            coefsNum = zeros( numel( comps ), numel( cvModels ) );
            for ll = 1 : numel( comps )
                for ii = 1 : numel( cvModels )
%                     cvModels{ii}.setLambda( lambdas(ll) );
                  cvModels{ii}.setComp( comps(ll) );
                    lPerfs(ll,ii) = IdModelInterface.getPerformance( ...
                        cvModels{ii}, obj.cvTrainer.folds{ii}, obj.positiveClass, ...
                        obj.performanceMeasure );
                    coefsPlusIntercept = glmnetCoef( cvModels{ii}.model, comps(ll) );
                    coefs(ll,ii,:) = coefsPlusIntercept(2:end);
                    coefsRel(ll,ii,:) = abs( coefs(ll,ii,:) ) ./ sum( abs( coefs(ll,ii,:) ) );
                    coefsNum(ll,ii) = sum( coefsRel(ll,ii,:) >= 0.1 / numel(coefsRel(ll,ii,:) ) );
                    verboseFprintf( obj, '.' );
                end
            end
            obj.fullSetModel.lPerfsMean = mean( lPerfs, 2 );
            obj.fullSetModel.lPerfsStd = std( lPerfs, [], 2 );
            obj.fullSetModel.nCoefs = mean( coefsNum, 2 );
            coefsRelAvg = squeeze( mean( coefsRel, 2 ) );
            obj.fullSetModel.coefsRelStd = squeeze( std( coefsRel, [], 2 ) ) ./ coefsRelAvg;
            verboseFprintf( obj, 'Done\n' );
%             obj.fullSetModel.lambdasSortedByPerf = sortrows( ...
%                 [lambdas,obj.fullSetModel.lPerfsMean - obj.fullSetModel.lPerfsStd], 2 );
obj.fullSetModel.compsSortedByPerf = sortrows( ...
                [comps,obj.fullSetModel.lPerfsMean - obj.fullSetModel.lPerfsStd], 2 );
%             bestLambda = mean( obj.fullSetModel.lambdasSortedByPerf(end-2:end,1) );
 bestComp = mean( obj.fullSetModel.compsSortedByPerf(end-2:end,1) );
            obj.fullSetModel.setComp( bestComp );
        end
        %% -------------------------------------------------------------------------------
        
        function performance = getPerformance( obj )
            performance = IdModelInterface.getPerformance( ...
                obj.fullSetModel, obj.testSet, obj.positiveClass, ...
                obj.performanceMeasure );
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.fullSetModel;
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
    end
        
end