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
            pds{3} = struct( 'name', 'cvFolds', ...
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
            obj.coreTrainer = GmmTrainer( ...
                'performanceMeasure', obj.parameters.performanceMeasure, ...
                'maxDataSize', obj.parameters.maxDataSize );
            obj.coreTrainer.setData( obj.trainSet, obj.testSet );
            obj.coreTrainer.setPositiveClass( obj.positiveClass );
            obj.coreTrainer.run();
            obj.fullSetModel = obj.coreTrainer.getModel();
%             lambdas = obj.fullSetModel.model.lambda;
%             verboseFprintf( obj, '\nRun cv to determine best lambda...\n' );
%             obj.coreTrainer.setParameters( false, 'lambda', lambdas );
            obj.cvTrainer = CVtrainer( obj.coreTrainer );
            obj.cvTrainer.setPerformanceMeasure( obj.performanceMeasure );
            obj.cvTrainer.setPositiveClass( obj.positiveClass );
            obj.cvTrainer.setData( obj.trainSet, obj.testSet );
            obj.cvTrainer.setNumberOfFolds( obj.parameters.cvFolds );
            obj.cvTrainer.run();
            cvModels = obj.cvTrainer.models;
%             verboseFprintf( obj, 'Calculate Performance for all lambdas...\n' );
%             lPerfs = zeros( numel( lambdas ), numel( cvModels ) );
%             coefs = zeros( numel( lambdas ), numel( cvModels ), ...
%                            obj.fullSetModel.model.dim(1) );
%             coefsRel = zeros( numel( lambdas ), numel( cvModels ), ...
%                            obj.fullSetModel.model.dim(1) );
%             coefsNum = zeros( numel( lambdas ), numel( cvModels ) );
%             for ll = 1 : numel( lambdas )
%                 for ii = 1 : numel( cvModels )
%                     cvModels{ii}.setLambda( lambdas(ll) );
%                     lPerfs(ll,ii) = IdModelInterface.getPerformance( ...
%                         cvModels{ii}, obj.cvTrainer.folds{ii}, obj.positiveClass, ...
%                         obj.performanceMeasure );
%                     coefsPlusIntercept = glmnetCoef( cvModels{ii}.model, lambdas(ll) );
%                     coefs(ll,ii,:) = coefsPlusIntercept(2:end);
%                     coefsRel(ll,ii,:) = abs( coefs(ll,ii,:) ) ./ sum( abs( coefs(ll,ii,:) ) );
%                     coefsNum(ll,ii) = sum( coefsRel(ll,ii,:) >= 0.1 / numel(coefsRel(ll,ii,:) ) );
%                     verboseFprintf( obj, '.' );
%                 end
%             end
%             obj.fullSetModel.lPerfsMean = mean( lPerfs, 2 );
%             obj.fullSetModel.lPerfsStd = std( lPerfs, [], 2 );
%             obj.fullSetModel.nCoefs = mean( coefsNum, 2 );
%             coefsRelAvg = squeeze( mean( coefsRel, 2 ) );
%             obj.fullSetModel.coefsRelStd = squeeze( std( coefsRel, [], 2 ) ) ./ coefsRelAvg;
%             verboseFprintf( obj, 'Done\n' );
%             obj.fullSetModel.lambdasSortedByPerf = sortrows( ...
%                 [lambdas,obj.fullSetModel.lPerfsMean - obj.fullSetModel.lPerfsStd], 2 );
%             bestLambda = mean( obj.fullSetModel.lambdasSortedByPerf(end-2:end,1) );
%             obj.fullSetModel.setLambda( bestLambda );
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