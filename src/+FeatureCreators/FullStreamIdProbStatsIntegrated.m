classdef FullStreamIdProbStatsIntegrated < FeatureCreators.BlackboardDepFeatureCreator
    %FULLSTREAMIDPROBSTATS5ABLOCKMEAN Summary of this class goes here
    %   Detailed explanation goes here
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        integratedFC;
        deltaLevels = 2;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FullStreamIdProbStatsIntegrated( featureCreator )
            obj = obj@FeatureCreators.BlackboardDepFeatureCreator();
            obj.integratedFC = featureCreator;
        end
        
        %% ----------------------------------------------------------------
        function [featureSignalVal, fList] = blackboardVal2FeatureSignalVal( ~, val )
            % turns one sample of blackboard data to a sample that can be
            % stored in a featureSignal
            idHyp = val.('identityHypotheses');
            featureSignalVal = {idHyp.p};
            fList = {idHyp.label};
        end
        
        %% ----------------------------------------------------------------
        
        function afeRequests = getAFErequests( obj )
            afeRequests = obj.integratedFC.getAFErequests();
        end
        %% -------------------------------------------------------------------------------
        
        
        function x = constructVector( obj )
            % constructVector for each feature: compress, scale, average
            %   over left and right channels, construct individual feature names
            %   returned flattened feature vector for entire block
            %   The AFE data is indexed according to the order in which the requests
            %   where made
            %
            %   See getAFErequests
            
            
            
            obj.integratedFC.blockAnnotations = obj.blockAnnotations;
            obj.integratedFC.baIdx = obj.baIdx;
            obj.integratedFC.afeData = obj.afeData;
            x = obj.integratedFC.constructVector();
            obj.integratedFC.descriptionBuilt = true;
            
            % afeIdx ? : idProbs
            idProbsIndex = numel(obj.integratedFC.getAFErequests()) + 1;
            idProbs = obj.makeBlockFromAfe( idProbsIndex, [], ...
                @(a)(a.Data), ...
                {@(a)('idProbs')}, ...
                {@(a)(strcat('t-', arrayfun(@(f)(num2str(f)), size(a.Data, 1)-1:-1:0, 'UniformOutput', false)))}, ...
                {@(a)(strcat('class:', a.fList))});
            
            if obj.deltaLevels >= size(idProbs{1}, 1)
                error('Not enough observations per block to generate the desired number of derivatives.');
            end
            
            plainProbs = obj.reshape2featVec(idProbs);
            x = obj.concatFeats( x, plainProbs );
            
            moments = obj.block2feat( idProbs, ...
                @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                2, @(idxs)(sort([idxs idxs])),...
                {{'1.LMom',@(idxs)(idxs(1:2:end))},...
                {'2.LMom',@(idxs)(idxs(2:2:end))}} );
            x = obj.concatFeats( x, moments );
            
            for ii = 1:obj.deltaLevels
                idProbs = obj.transformBlock( idProbs, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    @(idxs)(idxs(1:end-1)),...
                    {[num2str(ii) '.delta']} );
                delta = obj.block2feat( idProbs, ...
                    @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                    2, @(idxs)(sort([idxs idxs])),...
                    {{'1.LMom',@(idxs)(idxs(1:2:end))},...
                    {'2.LMom',@(idxs)(idxs(2:2:end))}} );
                x = obj.concatFeats( x, delta );
            end
            
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.integrated = obj.integratedFC.getFeatureInternOutputDependencies();
            outputDeps.deltaLevels = obj.deltaLevels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 1;
        end
    end
    
end

