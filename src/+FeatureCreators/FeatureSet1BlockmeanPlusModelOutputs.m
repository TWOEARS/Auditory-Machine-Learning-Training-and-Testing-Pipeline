classdef FeatureSet1BlockmeanPlusModelOutputs < FeatureCreators.Base
% FeatureSet1BlockmeanPlusModelOutputs 
%

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        baseFS1creator;
        numOrdinaryAFErequests;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet1BlockmeanPlusModelOutputs( )
            obj = obj@FeatureCreators.Base();
            obj.baseFS1creator = FeatureCreators.FeatureSet1Blockmean();
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests = obj.baseFS1creator.getAFErequests();
            obj.numOrdinaryAFErequests = numel( afeRequests );
        end
        %% ----------------------------------------------------------------

        function x = constructVector( obj )
            x = obj.baseFS1creator.constructVector();
            dnnLocFeatures = obj.makeBlockFromAfe( obj.numOrdinaryAFErequests+1, 1, ...
                @(a)(a.Data), ...
                {@(a)(a.Name)}, ...
                {'azm'}, ...
                {'prob'} );
            xDnnLoc = obj.block2feat( dnnLocFeatures, ...
                @(b)( b ), ...
                1, @(idxs)( idxs ),...
                {} );
            x = obj.concatFeats( x, xDnnLoc );
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.baseFS1deps = obj.baseFS1creator.getFeatureInternOutputDependencies();
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

