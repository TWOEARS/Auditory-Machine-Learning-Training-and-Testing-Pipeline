classdef FullStreamIdProbStats < FeatureCreators.BlackboardDepFeatureCreator
    %FULLSTREAMIDPROBSTATS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        idProbDeltaLevels = 2;
    end
    
    methods
        
        function obj = FullStreamIdProbStats( )
            obj = obj@FeatureCreators.BlackboardDepFeatureCreator();
        end
        %% ----------------------------------------------------------------
        
        function afeRequests = getAFErequests( ~ )
            afeRequests = [];
        end
        
        %% ----------------------------------------------------------------
        
        function [featureSignalVal, fList] = blackboardVal2FeatureSignalVal( ~, val )
            % turns one sample of blackboard data to a sample that can be
            % stored in a featureSignal
            idHyp = val.('identityHypotheses');
            featureSignalVal = [idHyp.p];
            fList = {idHyp.label};
        end
        
        
        %% ---------------------------------------------------------------
        
        function x = constructVector( obj )
            % constructVector for each feature: compress, scale, average
            %   over left and right channels, construct individual feature names
            %   returned flattened feature vector for entire block
            %   The AFE data is indexed according to the order in which the requests
            %   where made
            %
            %   See getAFErequests
            
            % afeIdx 1: idProbs
            idProbs = obj.makeBlockFromAfe( 1, [], ...
                @(a)(a.Data), ...
                {@(a)('idProbs')}, ...
                {@(a)(strcat('t-', arrayfun(@(f)(num2str(f)), size(a.Data, 1)-1:-1:0, 'UniformOutput', false)))}, ...
                {@(a)(strcat('class:', a.fList))});
            
            plainProbs = obj.reshape2featVec(idProbs);
            
            x = obj.block2feat( idProbs, ...
                @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                2, @(idxs)(sort([idxs idxs])),...
                {{'1.LMom',@(idxs)(idxs(1:2:end))},...
                {'2.LMom',@(idxs)(idxs(2:2:end))}} );
            
            for ii = 1:obj.idProbDeltaLevels
                idProbs = obj.transformBlock( idProbs, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    @(idxs)(idxs(1:end-1)),...
                    {[num2str(ii) '.delta']} );
                xtmp = obj.block2feat( idProbs, ...
                    @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                    2, @(idxs)(sort([idxs idxs])),...
                    {{'1.LMom',@(idxs)(idxs(1:2:end))},...
                    {'2.LMom',@(idxs)(idxs(2:2:end))}} );
                x = obj.concatFeats( x, xtmp );
            end
            
            x = obj.concatFeats( plainProbs, x );
            
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.idProbDeltaLevels = obj.idProbDeltaLevels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------
        
        
    end
    
end

