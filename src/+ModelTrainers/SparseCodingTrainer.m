classdef SparseCodingTrainer < ModelTrainers.Base & Parameterized
    % SparseCodingSelectTrainer trainer for a SparseCodingModel
    %   Will do sparse coding for given input to fit a base with sparse
    %   coefficients.
    %% --------------------------------------------------------------------
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        beta;
        Binit;
        num_bases;
        num_iters;
        
        % batch size of data that is computed in sparse coding at a
        % time, use an integer value smaller or equal to 
        % size(xScaled,1)
        batch_size; 
        
    end

    %% --------------------------------------------------------------------
    methods

        function obj = SparseCodingTrainer( varargin )
            pds{1} = struct( 'name', 'beta', ...
                             'default', 1, ...
                             'valFun', @(x)(isnumeric(x) && numel(x) == 1) );
            pds{2} = struct( 'name', 'num_bases', ...
                             'default', 100, ...
                             'valFun', @(x)(isnumeric(x) && numel(x) == 1) );
            pds{3} = struct( 'name', 'num_iters', ...
                             'default', 20, ...
                             'valFun', @(x)(isnumeric(x) && numel(x) == 1) );
            pds{4} = struct( 'name', 'batch_size', ...
                             'default', 5000, ...
                             'valFun', @(x)(isnumeric(x) && numel(x) == 1) );
            pds{5} = struct( 'name', 'Binit', ...
                             'default', [], ...
                             'valFun', @(x)(isnumeric(x)) );
            pds{6} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )          
            obj.model = Models.SparseCodingModel();
            x(isnan(x)) = 0;
            x(isinf(x)) = 0;
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            clear x;
            
            obj.batch_size = min( 5000, floor( size(xScaled, 1) / 2 ) );
            fname_save = sprintf('./sc_b%d_beta%g_%s', obj.num_bases, obj.beta, datestr(now, 30));	
            
            verboseFprintf( obj, 'Sparse Coding training\n' );
                         
            % the sparse coding script assumes the data columnwise, so
            % transpose input and output
            [B S stat] = sparse_coding(xScaled', obj.num_bases, obj.beta, 'L1', [], obj.num_iters, obj.batch_size, fname_save , obj.Binit);
            
            % set model parameter
            obj.model.B = B';
            
            % just for interest
            [fobj, ~, ~] = getObjective2(B, S, xScaled', 'L1', 1, obj.beta, 1, []);
            fprintf('\n==\tfobj on data: %f\n\n', fobj);
        end
        %% ----------------------------------------------------------------
            
        function performance = getPerformance( obj, getDatapointInfo )
            if nargin < 2, getDatapointInfo = 'noInfo'; end
            verboseFprintf( obj, 'Applying model to test set...\n' );
            obj.model.verbose( obj.verbose );
            
            % get test data
            xScaledTest = obj.model.scale2zeroMeanUnitVar( obj.testSet(:, 'x'));
            
            % fit activations of base to test data
            S = l1ls_featuresign(obj.model.B', xScaledTest', obj.beta);
            
            % feature sign creates S columnwise instead of rowwise, so
            % transpose S for evaluation of objective value
            [fobj, ~, ~] = getObjective2(obj.model.B', S, xScaledTest', 'L1', 1, obj.beta, 1, []);
            
            % calculate performance, normalize wrt to amount of data, also 
            % reverse fobj as a small value yields good performance
            perf = 1 /  (fobj / size(xScaledTest, 1));
            
            % set performance measure using fake meausure, as calculation 
            % has already been done above
            performance = PerformanceMeasures.Fake(perf, [], [], getDatapointInfo);
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