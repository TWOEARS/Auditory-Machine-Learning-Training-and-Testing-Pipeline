classdef GmmModel < DataScalingModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?GmmTrainer, ?GMMmodelSelectTrainer})
        model;
%         coefsRelStd;
%         lambdasSortedByPerf;
%         nCoefs;
    end
    
    %% --------------------------------------------------------------------
    methods

%         function obj = GmmModel()
%             obj.lambda = 1e-10;
%         end
        %% -----------------------------------------------------------------

%         function setLambda( obj, newLambda )
%             obj.lambda = newLambda;
%         end
        %% -----------------------------------------------------------------

%         function [impact, cIdx] = getCoefImpacts( obj, lambda )
%             if nargin < 2, lambda = obj.lambda; end
%             coefsAtLambda = abs( glmnetCoef( obj.model, lambda ) );
%             coefsAtLambda = coefsAtLambda / sum( coefsAtLambda );
%             [impact,cIdx] = sort( coefsAtLambda );
%         end
        %% -----------------------------------------------------------------

    end
    
    methods (Access = protected)
        
        function [y,score] = applyModelToScaledData( obj, x )
            model1 = obj.model{1};
            model0 = obj.model{2};
%             comps = featureSelectionPCA(x,1);
%  prinComps = comps(:,1: model1.NDimensions);
            idFeature = obj.model{3};
           
            [y] = gmmPredict(x(:,idFeature), model1, model0 );
            score = 1; % ask Ivo about?? ll
%             y = glmnetPredict( obj.model, x, obj.lambda, 'class' );
           
       end
        %% -----------------------------------------------------------------

    end
    
end

