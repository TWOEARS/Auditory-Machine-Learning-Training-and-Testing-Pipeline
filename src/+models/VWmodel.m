classdef VWmodel < models.DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?modelTrainers.VWtrainer, ?modelTrainers.VWmodelSelectTrainer})
        model;
        lrPerfsMean;
        lrPerfsStd;
    end

    %% --------------------------------------------------------------------
    properties
        learningRate;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = VWmodel()
        	learningRate=0.5;
        end
    	%% ----------------------------------------------------------------
    	
    	function setLearningRate( obj, newLearningRate )
            obj.learningRate = newLearningRate;
        end
        
        function r = getVWruntime(obj)
    		global vwRuntime;
    		r = vwRuntime;
    	end
    	
    	function setVWruntime(obj,runtime)
    		global vwRuntime;
    		vwRuntime = runtime;
    	end
        %% ----------------------------------------------------------------
    end
    
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
        	incomingTime = toc;
            score = [0];
            testFile = fopen(['vwtest',obj.model.modelName],'wt');
            [numberExamples, numberFeatures] = size(x);
            verboseFprintf( obj, 'Writing testfile.\n');
            prepTime = toc;
			for j = 1: numberExamples
				fprintf(testFile, '| ');
				for i = 1: numberFeatures
					fprintf(testFile, '%u:%f ', i, x(j,i));
				end
				fprintf(testFile, '\n');
			end
			fclose(testFile);
			writingTime = toc;
			verboseFprintf( obj, 'Getting predictions for the testdata.\n\n' );
			command = ['./../../third_party_software/vowpalwabbit/vw vwtest', ...
				obj.model.modelName,' -i ',obj.model.modelName,' -p vw.pred -c --binary'];
			if ~obj.verbose, command = [command, ' --quiet']; end
			system(command);
			predFile = fopen('vw.pred','r');
			y = fscanf(predFile, '%f');
			fclose(predFile);
			time = toc -incomingTime -(writingTime -prepTime);
			obj.setVWruntime(obj.getVWruntime+time);
			delete(['vwtest',obj.model.modelName],['vwtest',obj.model.modelName,'.cache']);
        end
    end
    
end

