classdef FeatureSet5Blockmean < FeatureCreators.Base

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        deltasLevels;
        compressor = 10;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet5Blockmean( )
            obj = obj@FeatureCreators.Base();
            obj.deltasLevels = 2;
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
            afeRequests{2}.name = 'spectralFeatures';
            afeRequests{2}.params = genParStruct( ...
                commonParams{:}, ...
                'fb_nChannels', 32, ...
                'sf_bUseInterp', false ...
                );
            afeRequests{3}.name = 'ratemap';
            afeRequests{3}.params = genParStruct( ...
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
            
            rm = obj.afeData(3);
            rmR = compressAndScale( rm{1}.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 );
            rmL = compressAndScale( rm{2}.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 );
            rm = 0.5 * rmR + 0.5 * rmL;
            sf = obj.afeData(2);
            sfR = sf{1}.Data;
            sfL = sf{2}.Data;
            sf = 0.5 * sfR + 0.5 * sfL;
            xb = cat( 2, rm, sf );
            if size( xb, 1 ) > 1
                x = lMomentAlongDim( xb, [1,2,3], 1, true );
            else
                x = xb;
            end
            for ii = 1:obj.deltasLevels
                xb = xb(2:end,:) - xb(1:end-1,:);
                if size( xb, 1 ) > 1
                    xtmp = lMomentAlongDim( xb, [1,2], 1, true );
                else
                    xtmp = xb;
                end
                if ~isempty( xtmp )
                    x = [x, xtmp]; %#ok<AGROW>
                end
            end
            mod = obj.afeData(1);
            modR = compressAndScale( mod{1}.Data, 1/obj.compressor );
            modL = compressAndScale( mod{2}.Data, 1/obj.compressor );
            % average between right and left channels
            mod = 0.5 * modR + 0.5 * modL;
            mod = reshape( mod, size( mod, 1 ), [] ); % flatten
            % append l-moments
            if size( mod, 1 ) > 1
                x = [x, lMomentAlongDim( mod, [1,2], 1, true )];
            elseif ~isempty( mod )
                    x = [x, mod];
            end
            % append first derivative
            for ii = 1:obj.deltasLevels
                mod = mod(2:end,:) - mod(1:end-1,:);
                if size( mod, 1 ) > 1
                    xtmp = lMomentAlongDim( mod, [1,2], 1, true );
                else
                    xtmp = mod;
                end
                if ~isempty( xtmp )
                    x = [x, xtmp]; %#ok<AGROW>
                end
            end
            x = {x};
            
            if ~obj.descriptionBuilt
                x_ = x;

                rmR = obj.makeBlockFromAfe( 3, 1, ...
                    @(a)(compressAndScale( a.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 )), ...
                    {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                    {'t'}, ...
                    {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
                rmL = obj.makeBlockFromAfe( 3, 2, ...
                    @(a)(compressAndScale( a.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 )), ...
                    {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                    {'t'}, ...
                    {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
                rm = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', rmR, rmL );
                spfR = obj.makeBlockFromAfe( 2, 1, ...
                    @(a)(a.Data ), ...
                    {@(a)(a.Name),'32-ch', ...
                    @(a)(a.Channel)}, ...
                    {'t'}, ...
                    {@(a)(a.fList)} );
                spfL = obj.makeBlockFromAfe( 2, 2, ...
                    @(a)(a.Data), ...
                    {@(a)(a.Name),'32-ch',...
                    @(a)(a.Channel)}, ...
                    {'t'}, ...
                    {@(a)(a.fList)} );
                spf = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', spfR, spfL );
                xb = obj.concatBlocks( 2, rm, spf );
                if size( xb{1}, 1 ) > 1
                    x = obj.block2feat( xb, ...
                        @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                        2, @(idxs)(sort([idxs idxs idxs])),...
                        {{'1.LMom',@(idxs)(idxs(1:3:end))},...
                        {'2.LMom',@(idxs)(idxs(2:3:end))},...
                        {'3.LMom',@(idxs)(idxs(3:3:end))}} );
                else
                    x = obj.block2feat( xb, ...
                        @(b)(b), 2, @(idxs)(sort(idxs)), {} );
                end
                for ii = 1:obj.deltasLevels
                    xb = obj.transformBlock( xb, 1, ...
                        @(b)(b(2:end,:) - b(1:end-1,:)), ...
                        @(idxs)(idxs(1:end-1)),...
                        {[num2str(ii) '.delta']} );
                    if size( xb{1}, 1 ) > 1
                        xtmp = obj.block2feat( xb, ...
                            @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                            2, @(idxs)(sort([idxs idxs])),...
                            {{'1.LMom',@(idxs)(idxs(1:2:end))},...
                            {'2.LMom',@(idxs)(idxs(2:2:end))}} );
                    else
                        xtmp = obj.block2feat( xb, ...
                            @(b)(b), 2, @(idxs)(sort(idxs)), {} );
                    end
                    if ~isempty( xtmp{1} )
                        x = obj.concatFeats( x, xtmp );
                    end
                end
                modR = obj.makeBlockFromAfe( 1, 1, ...
                    @(a)(compressAndScale( a.Data, 1/obj.compressor )), ...
                    {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                    {'t'}, ...,
                    {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz,'UniformOutput', false)))}, ...
                    {@(a)(strcat('mf', arrayfun(@(f)(num2str(f)), a.modCfHz,'UniformOutput', false)))} );
                modL = obj.makeBlockFromAfe( 1, 2, ...
                    @(a)(compressAndScale( a.Data, 1/obj.compressor )), ...
                    {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ... % groups
                    {'t'}, ... % varargin: time index
                    {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz,'UniformOutput', false)))}, ... % varargin: freq. bins
                    {@(a)(strcat('mf', arrayfun(@(f)(num2str(f)), a.modCfHz,'UniformOutput', false)))} ); % vararing: modulation frequencies
                % average between right and left channels
                mod = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', modR, modL );
                mod = obj.reshapeBlock( mod, 1 ); % flatten
                % append l-moments
                if size( mod{1}, 1 ) > 1
                    x = obj.concatFeats( x, obj.block2feat( mod, ...
                        @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                        2, @(idxs)(sort([idxs idxs])),...
                        {{'1.LMom', @(idxs)(idxs(1:2:end))},...
                        {'2.LMom', @(idxs)(idxs(2:2:end))}} ) );
                elseif ~isempty( mod{1} )
                    x = obj.concatFeats( x, obj.block2feat( mod, ...
                        @(b)(b), 2, @(idxs)(sort(idxs)), {} ) );
                end
                % append first derivative
                for ii = 1:obj.deltasLevels
                    mod = obj.transformBlock( mod, 1, ...
                        @(b)(b(2:end,:) - b(1:end-1,:)), ...
                        @(idxs)(idxs(1:end-1)),...
                        {[num2str(ii) '.delta']} );
                    if size( mod{1}, 1 ) > 1
                        x = obj.concatFeats( x, obj.block2feat( mod, ...
                            @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                            2, @(idxs)(sort([idxs idxs])),...
                            {{'1.LMom', @(idxs)(idxs(1:2:end))},...
                            {'2.LMom', @(idxs)(idxs(2:2:end))}} ) );
                    elseif ~isempty( mod{1} )
                        x = obj.concatFeats( x, obj.block2feat( mod, ...
                            @(b)(b), 2, @(idxs)(sort(idxs)), {} ) );
                    end
                end
                
                % sanity check: code above produces the same features as
                % code in here
                assert( all( all( x_{1} == x{1} ) ) );
            end
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.deltasLevels = obj.deltasLevels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 2;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

