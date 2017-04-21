classdef SparseCodingSelectTrainer < ModelTrainers.Base & Parameterized
    % SparseCodingSelectTrainer trainer for a SparseCodingModel
    %   Will do sparse coding for given input to fit a base with sparse
    %   coefficients. This trainer will additionally do a k-fold 
    %   crossvalidation to choose the best sparsity factor lambda as well 
    %   as the dimension of the base along the path according to a 
    %   performance measure.
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        cvTrainer;      % for k-fold cross validation
        coreTrainer;
        fullSetModel;
        nLambda;        % number of lambdas on the regularization path
        cvFolds;        % no. of folds for cross validation
        % think about how to cv dimension of base
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = SparseCodingSelectTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @PerformanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            %TODO check which values and range of lambdas make sense
            pds{3} = struct( 'name', 'nLambda', ...
                             'default', 100, ...
                             'valFun', @(x)(rem(x,1) == 0 && x >= 0) );  %rem(x,1) -> remainder after division with 1 = 0 => integer
            pds{4} = struct( 'name', 'cvFolds', ...
                              'default', 10, ...
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
        
end