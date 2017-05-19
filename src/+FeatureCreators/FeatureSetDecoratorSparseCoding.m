classdef FeatureSetDecoratorSparseCoding < FeatureCreators.Base
% FeatureSetDecoratorSparseCoding Specifies a sparse feature set for a 
% given feature creator and a given sparse coding model
%   see FeatureSetDecoratorSparseCoding.getAFErequests()

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        featureCreator;
        sparseCodingModel;
        beta;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSetDecoratorSparseCoding( featureCreator, sparseCodingModel, beta )
            % check if input featureCreator is valid
            if ~exist('featureCreator', 'var') || ...
                    ~isa(featureCreator, 'FeatureCreators.Base')
                
                error('You need to pass a valid feature creator to this decorator')
            end
            % check if input sparseCodingModel is valid
            if ~exist('sparseCodingModel', 'var') || ...
                    ~isa(sparseCodingModel, 'Models.SparseCodingModel')
                
                error('You need to pass a valid sparse coding model to this decorator')
            end
            
             % check if input beta is valid
            if ~exist('beta', 'var') || ...
                    ~isa(beta, 'double')
                
                error('You need to pass a valid beta (sparsity factor) to this decorator')
            end
            
            obj = obj@FeatureCreators.Base();
            % set properties
            obj.featureCreator      = featureCreator;
            obj.sparseCodingModel   = sparseCodingModel;
            obj.beta                = beta;
        end
        %% ----------------------------------------------------------------      
        
        function afeRequests = getAFErequests( obj )
            % TODO enough to call AFE requests?
            afeRequests = obj.featureCreator.getAFErequests;
        end
        %% ----------------------------------------------------------------

        function x = constructVector( obj )
            % pass afeData to wrapped feature creator
            obj.featureCreator.afeData = obj.afeData;
            % calculate feature vector from given feature creator
            feature        = obj.featureCreator.constructVector;
            
            % TODO wrapped feature creator has to agree with the one used in the model   
            featureScaled  = obj.sparseCodingModel.scale2zeroMeanUnitVar(feature{1});
             
            % optimize activation of base wrt feature vector 
            % (transpose B and feature vector because featuresign algorithm
            % assumes columnwise data)
            S = l1ls_featuresign(obj.sparseCodingModel.B', featureScaled', obj.beta);
            
            % the optimized sparse activation is now our feature vector
            x = {S', feature{2}};
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            % TODO what does this method do?
            
            outputDeps.featureCreator       = obj.featureCreator;
            outputDeps.sparseCodingModel    = obj.sparseCodingModel;
            outputDeps.beta                 = obj.beta;
            
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------
        
        
%         function setAfeData( obj, afeData )
%             obj.afeData = afeData;
%         end
%         %% -------------------------------------------------------------------------------
%         
%         % override from Base to call for wrapped feature creator as well
%         function process( obj, wavFilepath )
%             process@FeatureCreators.Base(obj, wavFilepath);
%         end
%         %% -------------------------------------------------------------------------------
%         
%         %% -------------------------------------------------------------------------------
% 
%         % override from Base to call for wrapped feature creator as well
%         function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
%           	[out, outFilepath] = loadProcessedData@FeatureCreators.Base(obj, wavFilepath, varargin); 
%         end
%         %% -------------------------------------------------------------------------------
% 
%         % override from Base to call for wrapped feature creator as well
%         function save( obj, wavFilepath, ~ )
%             save@FeatureCreators.Base(obj, wavFilepath);
%         end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

