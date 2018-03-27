classdef BlackboardDepFeatureCreator < FeatureCreators.Base
    %BLACKBOARDDEPFEATURECREATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Abstract)
        [featureSignalVal, fList] = blackboardVal2FeatureSignalVal( obj, val )
    end
    
    methods
        function obj = BlackboardDepFeatureCreator()
            obj = obj@FeatureCreators.Base();
        end
    end
    
end