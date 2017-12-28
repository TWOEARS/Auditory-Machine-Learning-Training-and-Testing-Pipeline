classdef FeatureSet5aRawTimeSeries < FeatureCreators.Base

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        compressor = 10;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet5aRawTimeSeries( )
            obj = obj@FeatureCreators.Base();
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            commonParams = FeatureCreators.LCDFeatureSet.getCommonAFEParams();
            afeRequests{1}.name = 'amsFeatures';
            afeRequests{1}.params = genParStruct( ...
                commonParams{:}, ...
                'fb_nChannels', 16, ...
                'ams_fbType', 'log', ...
                'ams_nFilters', 8, ...
                'ams_lowFreqHz', 2, ...
                'ams_highFreqHz', 256', ...
                'ams_wSizeSec', 128e-3, ...
                'ams_hSizeSec', 32e-3 ...
                );
            afeRequests{2}.name = 'ratemap';
            afeRequests{2}.params = genParStruct( ...
                commonParams{:}, ...
                'fb_nChannels', 32 ...
                );
        end
        %% ----------------------------------------------------------------

        function x = constructVector( obj )
            % constructVector for each feature: compress, scale, average
            %   over left and right channels, construct individual feature names
            %   returned flattened feature vector for entire block
            %   The AFE data is indexed according to the order in which the requests
            %   where made
            % 
            %   See getAFErequests
            
            % afeIdx 1: ams
            modR = obj.makeBlockFromAfe( 1, 1, ...
                @(a)(compressAndScale( a.Data, 1/obj.compressor )), ...
                {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...,
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz,'UniformOutput', false)))}, ...
                {@(a)(strcat('mf', arrayfun(@(f)(num2str(f)), a.modCfHz,'UniformOutput', false)))} );
            modL = obj.makeBlockFromAfe( 1, 2, ...
                @(a)(compressAndScale( a.Data, 1/obj.compressor )), ...
                {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ... % groups
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ... % varargin: time index
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz,'UniformOutput', false)))}, ... % varargin: freq. bins
                {@(a)(strcat('mf', arrayfun(@(f)(num2str(f)), a.modCfHz,'UniformOutput', false)))} ); % vararing: modulation frequencies
            % afeIdx 2: rm
            rmR = obj.makeBlockFromAfe( 2, 1, ...
                @(a)(compressAndScale( a.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
            rmL = obj.makeBlockFromAfe( 2, 2, ...
                @(a)(compressAndScale( a.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
            % average between right and left channels
            rm = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', rmR, rmL );
            mod = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', modR, modL );
            mod = obj.reshapeBlock( mod, 1 ); % flatten

            x = obj.concatFeats( obj.reshape2featVec( rm ), obj.reshape2featVec( mod ) );
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.compressor = obj.compressor;
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

