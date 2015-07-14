classdef vMFModel < models.DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?modelTrainers.vMFTrainer, ?modelTrainers.GMMmodelSelectTrainer})
        model;
%         coefsRelStd;
%         lambdasSortedByPerf;
%         nCoefs;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            model1 = obj.model{1};
            model0 = obj.model{2};
            idFeature = obj.model{3};
            % use apparoch 1 if thraining is done with approach 1
            xTest = x(:,idFeature);
            % use approach 2 if trianing is done with approach 2
%              [~,reconst] = pcares(x,idFeature);
%               xTest= reconst(:,1:idFeature);
            
            % do prediction
            [y, score] = vMFPredict((normvec(xTest'))', model1, model0 );
                       
       end
        %% -----------------------------------------------------------------

    end
    
end

