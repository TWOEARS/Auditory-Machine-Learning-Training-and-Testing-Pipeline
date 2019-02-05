classdef RFmodelSelectTrainer < ModelTrainers.HpsTrainer & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        hpsNtreesRange;
        method;
        hpsMinLeafSizeRange;
        hpsNumPredictorsToSampleFunctions;
        hpsInBagSamplesRange;
        predictorSelection;
        useSelectHeuristic;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = RFmodelSelectTrainer( varargin )
            pds{1} = struct( 'name', 'hpsNtreesRange', ...
                             'default', [1 3], ...
                             'valFun', @(x)(isfloat(x) && length(x)==2 && x(1) < x(2)) && x(1) >= 0 );
            pds{2} = struct( 'name', 'method', ...
                             'default', 'classification', ...
                             'valFun', @(x)(ischar(x) && any(strcmpi(x, ...
                                                                     {'classification',...
                                                                      'regression'}))) );
            pds{3} = struct( 'name', 'hpsMinLeafSizeRange', ...
                             'default', [0 2], ...
                             'valFun', @(x)(isfloat(x) && length(x)==2 && x(1) < x(2) && x(1) >= 0) );
            pds{4} = struct( 'name', 'hpsNumPredictorsToSampleFunctions', ...
                             'default', {@(nFeatures)(max( 1, floor( sqrt( nFeatures ) ) ))}, ...
                             'valFun', @(x)(all( cellfun(@(c)(rem(c(1),1) == 0 && c(1) > 0), x ))) );
            pds{5} = struct( 'name', 'hpsInBagSamplesRange', ...
                             'default', [-inf inf], ...
                             'valFun', @(x)(isfloat(x) && length(x)==2 && x(1) < x(2)) );
            pds{6} = struct( 'name', 'predictorSelection', ...
                             'default', 'allsplits', ...
                             'valFun', @(x)(ischar(x) && any(strcmpi(x, ...
                                                                     {'curvature',...
                                                                      'allsplits',...
                                                                      'interaction-curvature'}))) );
            pds{7} = struct( 'name', 'useSelectHeuristic', ...
                             'default', false, ...
                             'valFun', @islogical );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.HpsTrainer( varargin{:} );
            obj.setParameters( true, ...
                'buildCoreTrainer', @ModelTrainers.RandomForestTrainer, ...
                'hpsCoreTrainerParams', ...
                    {'method', obj.method,...
                     'predictorSelection', obj.predictorSelection,...
                     'dataSelector',obj.dataSelector, ...
                     'importanceWeighter',obj.importanceWeighter}, ...
                varargin{:} );
            obj.setParameters( false, 'finalCoreTrainerParams', ...
                                      {'method', obj.method,...
                                       'predictorSelection', obj.predictorSelection,...
                                       'dataSelector',obj.dataSelector,...
                                       'importanceWeighter',obj.importanceWeighter} );
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function hpsSets = getHpsRandomSearchSets( obj )
            hpsSets = zeros( 0, 4 );
            while size( hpsSets, 1 ) < obj.hpsSearchBudget(1)
                hpsMLSs = rand( 1 );
                hpsNPSs = randi( numel( obj.hpsNumPredictorsToSampleFunctions ) );
                hpsIBFs = rand( 1 );
                hpsNTs = rand( 1 );
                hpsSets(end+1,:) = cat( 2, hpsNTs, hpsIBFs, hpsMLSs, hpsNPSs ); %#ok<AGROW>
                hpsSets = uniquetol( hpsSets, 0.05, 'ByRows', true );
            end
            hpsSets(:,1) = round( 10.^( (obj.hpsNtreesRange(2) - obj.hpsNtreesRange(1)) ...
                                                  * hpsSets(:,1) + obj.hpsNtreesRange(1) ) );
            hpsSets(:,2) = round( 10.^( (obj.hpsInBagSamplesRange(2) - obj.hpsInBagSamplesRange(1)) ...
                                                  * hpsSets(:,2) + obj.hpsInBagSamplesRange(1) ) );
            hpsSets(:,3) = round( 10.^( (obj.hpsMinLeafSizeRange(2) - obj.hpsMinLeafSizeRange(1)) ...
                                                  * hpsSets(:,3) + obj.hpsMinLeafSizeRange(1) ) );
            hpsSets = num2cell( hpsSets );
            hpsSets(:,4) = obj.hpsNumPredictorsToSampleFunctions([hpsSets{:,4}]);
            hpsSets = hpsSets(randperm( size( hpsSets, 1 ) ),:);
            hpsSets = cell2struct( hpsSets, {'nTrees','inBagSamples','minLeafSize','numPredictorsToSample'},2 );
        end
        %% -------------------------------------------------------------------------------
        
        function hpsSets = getHpsGridSearchSets( obj )
            error( 'AMLTTP:featureNotImplemented', 'random forest grid search not implemented.' );
        end
        %% -------------------------------------------------------------------------------
        
        function refineGridTrainer( obj, hps )
            numBests = ceil( obj.hpsSearchBudget(1) / 2 );
            bestParamSets = hps.params(end-numBests+1:end);
            ntRefinedRange = [floor( 3 * log10( min( [bestParamSets.nTrees] ) ) ) / 3, ...
                              ceil( 3 * log10( max( [bestParamSets.nTrees] ) ) ) / 3];
            ibfRefinedRange = [floor( 3 * log10( min( [bestParamSets.inBagSamples] ) ) ) / 3, ...
                               ceil( 3 * log10( max( [bestParamSets.inBagSamples] ) ) ) / 3];
            mlsRefinedRange = [floor( 5 * log10( min( [bestParamSets.minLeafSize] ) ) ) / 5, ...
                               ceil( 5 * log10( max( [bestParamSets.minLeafSize] ) ) ) / 5];
            npsRefinedRange = {bestParamSets.numPredictorsToSample};
            obj.setParameters( false, ...
                'hpsNtreesRange', ntRefinedRange, ...
                'hpsInBagSamplesRange', ibfRefinedRange, ...
                'hpsMinLeafSizeRange', mlsRefinedRange, ...
                'hpsNumPredictorsToSampleFunctions', npsRefinedRange );
        end
        %% -------------------------------------------------------------------------------

        % override
        function hpsAddInfo = getHpsAddInfo( obj )
            tTrain = cellfun( @(c)(c.trainTime), obj.hpsCVtrainer.models );
            hpsAddInfo.tTrain = mean( tTrain );
        end
        %% -------------------------------------------------------------------------------

        % override
        function hps = sortHpsSetsByPerformance( obj, hps )
            hps = sortHpsSetsByPerformance@ModelTrainers.HpsTrainer( obj, hps );
            if obj.useSelectHeuristic
                s = hps.stds;
                t = [hps.addInfo.tTrain];
                t = t ./ max( t );
                rPenalty = s .* t;
                for ii = 1 : numel( hps.perfs )
                    p(ii) = hps.perfs(ii) - rPenalty(ii); %#ok<AGROW>
                end
                [~,idx] = sort( p );
                hps.perfs = hps.perfs(idx);
                hps.stds = hps.stds(idx);
                hps.dataSizes = hps.dataSizes(idx);
                hps.testDataSizes = hps.testDataSizes(idx);
                hps.params = hps.params(idx);
                hps.addInfo = hps.addInfo(idx);
            end
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
    end
    
end