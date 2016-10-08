classdef VWtrainer < modelTrainers.Base & Parameterized
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        model;
        passes;
        lossFunction;
        learningRate;
        learningRateDecay;
        lambda1;
        lambda2;
        initialT;
        powerT;
        noconstant;
        binary;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = VWtrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @performanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'passes', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x > 0) );
            pds{3} = struct( 'name', 'lossFunction', ...
                             'default', 'logistic', ...
                             'valFun', @(x)(strcmpi(x,'squared') || strcmpi(x,'hinge') ...
                             	|| strcmpi(x,'logistic') || strcmpi(x,'quantile') || strcmpi(x,'poisson')) );
            pds{4} = struct( 'name', 'learningRate', ...
                             'default', 0.5, ...
                             'valFun', @(x)(isfloat(x) && x >= 0) );
            pds{5} = struct( 'name', 'learningRateDecay', ...
                             'default', 1, ...
                             'valFun', @(x)(isfloat(x) && x >= 0) );
            pds{6} = struct( 'name', 'lambda1', ...
                             'default', 0, ...
                             'valFun', @(x)(isfloat(x) && x >= 0) );
            pds{7} = struct( 'name', 'lambda2', ...
                             'default', 0, ...
                             'valFun', @(x)(isfloat(x) && x >= 0) );
            pds{8} = struct( 'name', 'initialT', ...
                             'default', 0, ...
                             'valFun', @(x)(isfloat(x) && x >= 0) );
            pds{9} = struct( 'name', 'powerT', ...
                             'default', 0.5, ...
                             'valFun', @(x)(isfloat(x) && x >= 0) );
            pds{10} = struct( 'name', 'noconstant', ...
                             'default', false, ...
                             'valFun', @islogical );
            pds{11} = struct( 'name', 'binary', ...
                             'default', true, ...
                             'valFun', @islogical );
            pds{12} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------
        function buildModel( obj, x, y )
        	incomingTime = toc;
        	obj.model = models.VWmodel();
        	modelName = sprintf('model%f',cputime);
            dataFile = fopen(['vwtrain',modelName],'wt');
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
			[numberExamples, numberFeatures] = size(x);
			verboseFprintf( obj, '\nWriting trainingfile.\n' );
			weight = sum(y==-1)/size(y,1);
			prepTime = toc;
			for j = 1: numberExamples
				if y(j)<0
					fprintf(dataFile, '%i %f | ', y(j), weight );
				else
					fprintf(dataFile, '%i | ', y(j));
				end
				for i = 1: numberFeatures
					fprintf(dataFile, '%u:%f ', i, x(j,i));
				end
				fprintf(dataFile, '\n');
			end
			fclose(dataFile);
			writingTime = toc;
			verboseFprintf( obj, 'Running Vowpal Wabbit on trainingdata.\n\n' );
			vwParamStrScheme = [' --passes %u --loss_function %s --learning_rate %f ', ... 
				'--decay_learning_rate %f --l1 %f --l2 %f --initial_t %f --power_t %f '];
            vwParamStr = sprintf( vwParamStrScheme, ...
                obj.passes, obj.lossFunction, obj.learningRate, ...
                obj.learningRateDecay, obj.lambda1, obj.lambda2, ...
                obj.initialT, obj.powerT );
            if obj.noconstant, vwParamStr = [vwParamStr, ' --noconstant']; end
            if obj.binary, vwParamStr = [vwParamStr, ' --binary']; end
            if ~obj.verbose, vwParamStr = [vwParamStr, ' --quiet']; end
			command = ['./../../third_party_software/vowpalwabbit/vw vwtrain', modelName, ... 
				' -c -f ', modelName, vwParamStr];
			system(command);
			time = toc -incomingTime -(writingTime -prepTime);
			if isempty(obj.model.getVWruntime), obj.model.setVWruntime(0); end
			obj.model.setVWruntime(obj.model.getVWruntime+time);
			VWmodel = struct('modelName',modelName,'vwRuntime',obj.model.getVWruntime);
			obj.model.model = VWmodel;
			delete(['vwtrain',modelName],['vwtrain',modelName,'.cache']);
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
