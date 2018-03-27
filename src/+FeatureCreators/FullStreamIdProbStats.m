classdef FullStreamIdProbStats < FeatureCreators.BlackboardDepFeatureCreator
    %FULLSTREAMIDPROBABILITIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        deltasLevels = 2;
        compressor = 10;
    end
    
    methods
        
        function obj = FullStreamIdProbStats( )
            obj = obj@FeatureCreators.BlackboardDepFeatureCreator();
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests = [];
        end
        
        %% ----------------------------------------------------------------
        
        function [featureSignalVal, fList] = blackboardVal2FeatureSignalVal( obj, val )
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
                @(a)(compressAndScale( a.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)('idProbs')}, ...
                {'t'}, ...
                {@(a)(strcat('class-', a.fList))});            
            plainProbs = obj.reshape2featVec(idProbs);
            x = obj.block2feat( idProbs, ...
                @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                2, @(idxs)(sort([idxs idxs idxs])),...
                {{'1.LMom',@(idxs)(idxs(1:3:end))},...
                 {'2.LMom',@(idxs)(idxs(2:3:end))},...
                 {'3.LMom',@(idxs)(idxs(3:3:end))}} );
            for ii = 1:obj.deltasLevels
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
            outputDeps.deltasLevels = obj.deltasLevels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------

   
    end
    
end

