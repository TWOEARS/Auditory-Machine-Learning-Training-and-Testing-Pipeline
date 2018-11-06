classdef FeatureSet5bBlockmean < FeatureCreators.Base

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        deltasLevels;
        compressor = 10;
        sfProc;
        softMask;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet5bBlockmean( )
            obj = obj@FeatureCreators.Base();
            obj.deltasLevels = 2;
            afeRequests = obj.getAFErequests();
            fbProc = gammatoneProc( [], afeRequests{2}.params );
            obj.sfProc = spectralFeaturesProc( [], afeRequests{2}.params );
            obj.sfProc.addLowerDependencies( {fbProc} );
            obj.sfProc.prepareForProcessing( 'bUseInterp', false );
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
        
        % override of FeatureCreators.Base's method
        function process( obj, wavFilepath )
            inData = obj.loadInputData( wavFilepath );
            obj.blockAnnotations = [inData.blockAnnotations{:}]';
            obj.x = [];
            runningBaIdx = 0;
            for ii = 1 : numel( inData.blockAnnotations)
                obj.afeData = inData.afeBlocks{ii};
                for jj = 1 : numel( inData.blockAnnotations{ii} )
                    runningBaIdx = runningBaIdx + 1;
                    obj.baIdx = runningBaIdx;
                    obj.softMask = inData.ksData{ii}(jj);
                    xd = obj.constructVector();
                    if isempty( obj.x )
                        obj.x = zeros( numel( obj.blockAnnotations ), size( xd{1}, 1 ), size( xd{1}, 2 ) );
                    end
                    obj.x(runningBaIdx,:,:) = xd{1};
                    fprintf( '.' );
                    if obj.descriptionBuilt, continue; end
                    obj.description = xd{2};
                    obj.descriptionBuilt = true;
                end
            end
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

            sm = obj.softMask;
            softmask = (sm.Data) .^ obj.compressor;
            obj.afeData = SegmentIdentityKS.maskAFEData( obj.afeData, softmask, sm.cfHz, 1/sm.FsHz );

            obj.sfProc.reset();
            
            rm = obj.afeData(2);
            rmR = compressAndScale( rm{1}.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 );
            rmL = compressAndScale( rm{2}.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 );
            rmLR = 0.5 * rmR + 0.5 * rmL;
            x = lMomentAlongDim( rmLR, [1,2,3], 1, true );
            for ii = 1:obj.deltasLevels
                rmLR = rmLR(2:end,:) - rmLR(1:end-1,:);
                xtmp = lMomentAlongDim( rmLR, [1,2], 1, true );
                x = [x, xtmp]; %#ok<AGROW>
            end
            % afeIdx 1: amsFeatures and generate corresponding feature names
            mod = obj.afeData(1);
            modR = compressAndScale( mod{1}.Data, 1/obj.compressor );
            modL = compressAndScale( mod{2}.Data, 1/obj.compressor );
            % average between right and left channels
            mod = 0.5 * modR + 0.5 * modL;
            mod = reshape( mod, size( mod, 1 ), [] ); % flatten
            % append l-moments
            x = [x, lMomentAlongDim( mod, [1,2], 1, true )];
            % append first derivative
            for ii = 1:obj.deltasLevels
                mod = mod(2:end,:) - mod(1:end-1,:);
                x = [x, lMomentAlongDim( mod, [1,2], 1, true )]; %#ok<AGROW>
            end
            % softMask
            x = [x, lMomentAlongDim( sm.Data, [1,2,3], 1, true )];
            x = [x, sum( sm.Data(:) )];
            curBA = obj.blockAnnotations(obj.baIdx);
            x = [x, curBA.nStreams];
            % compute masked spectral features
            sf = obj.sfProc.processChunk( 0.5*rm{1}.Data + 0.5*rm{2}.Data );
            x = [x, lMomentAlongDim( sf, [1,2,3], 1, true )];
            sfd = sf;
            for ii = 1:obj.deltasLevels
                sfd = sfd(2:end,:) - sfd(1:end-1,:);
                xtmp = lMomentAlongDim( sfd, [1,2], 1, true );
                x = [x, xtmp]; %#ok<AGROW>
            end
            x = {x};
            
            if ~obj.descriptionBuilt
                x_ = x;

                rmR = obj.makeBlockFromAfe( 2, 1, ...
                    @(a)(compressAndScale( a.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 )), ...
                    {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                    {'t'}, ...
                    {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
                rmL = obj.makeBlockFromAfe( 2, 2, ...
                    @(a)(compressAndScale( a.Data, 1/obj.compressor, @(x)(median( x(x>0.01) )), 0 )), ...
                    {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                    {'t'}, ...
                    {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
                rm = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', rmR, rmL );
                x = obj.block2feat( rm, ...
                    @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                    2, @(idxs)(sort([idxs idxs idxs])),...
                    {{'1.LMom',@(idxs)(idxs(1:3:end))},...
                     {'2.LMom',@(idxs)(idxs(2:3:end))},...
                     {'3.LMom',@(idxs)(idxs(3:3:end))}} );
                for ii = 1:obj.deltasLevels
                    rm = obj.transformBlock( rm, 1, ...
                        @(b)(b(2:end,:) - b(1:end-1,:)), ...
                        @(idxs)(idxs(1:end-1)),...
                        {[num2str(ii) '.delta']} );
                    xtmp = obj.block2feat( rm, ...
                        @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                        2, @(idxs)(sort([idxs idxs])),...
                        {{'1.LMom',@(idxs)(idxs(1:2:end))},...
                         {'2.LMom',@(idxs)(idxs(2:2:end))}} );
                    x = obj.concatFeats( x, xtmp );
                end
                % afeIdx 1: amsFeatures and generate corresponding feature names
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
                x = obj.concatFeats( x, obj.block2feat( mod, ...
                    @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                    2, @(idxs)(sort([idxs idxs])),...
                    {{'1.LMom', @(idxs)(idxs(1:2:end))},...
                     {'2.LMom', @(idxs)(idxs(2:2:end))}} ) );
                % append first derivative
                for ii = 1:obj.deltasLevels
                    mod = obj.transformBlock( mod, 1, ...
                        @(b)(b(2:end,:) - b(1:end-1,:)), ...
                        @(idxs)(idxs(1:end-1)),...
                        {[num2str(ii) '.delta']} );
                    x = obj.concatFeats( x, obj.block2feat( mod, ...
                        @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                        2, @(idxs)(sort([idxs idxs])),...
                        {{'1.LMom', @(idxs)(idxs(1:2:end))},...
                         {'2.LMom', @(idxs)(idxs(2:2:end))}} ) );
                end
                % softmask
                obj.afeData(3) = obj.softMask;
                sm = obj.makeBlockFromAfe( 3, 1, ...
                    @(a)(a.Data), ...
                    {@(a)(a.Name), @(a)([num2str(numel(a.cfHz)) '-ch']), @(a)(a.Channel)}, ...
                    {'t'}, ...
                    {@(a)(strcat('f', arrayfun(@(f)(num2str(f)), a.cfHz, 'UniformOutput', false)))} );
                xtmp = obj.block2feat( sm, ...
                    @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                    2, @(idxs)(sort([idxs idxs idxs])),...
                    {{'1.LMom',@(idxs)(idxs(1:3:end))},...
                     {'2.LMom',@(idxs)(idxs(2:3:end))},...
                     {'3.LMom',@(idxs)(idxs(3:3:end))}} );
                x = obj.concatFeats( x, xtmp );
                sumSM = obj.block2feat( sm, ...
                    @(b)(sum( b(:) )), ...
                    1, @(idxs)(1),...
                    {{'Sum',@(idxs)(1)}} );
                x = obj.concatFeats( x, sumSM );
                curBA = obj.blockAnnotations(obj.baIdx);
                baNs = {curBA.nStreams,{{'nSpatialStreams'}}};
                x = obj.concatFeats( x, baNs );
                % compute masked spectral features
                sf = {sf,...
                       repmat({{'Masked','SpectralFeatures','32-ch','LRmean','t'}}, 1, size( sf, 1 )),...
                       cellfun( @(c1,c2)([c1,c2]), repmat({{'Masked','SpectralFeatures','32-ch','LRmean'}}, 1, size( sf, 2 )), obj.sfProc.requests, 'UniformOutput', false )};
                xtmp = obj.block2feat( sf, ...
                    @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                    2, @(idxs)(sort([idxs idxs idxs])),...
                    {{'1.LMom',@(idxs)(idxs(1:3:end))},...
                     {'2.LMom',@(idxs)(idxs(2:3:end))},...
                     {'3.LMom',@(idxs)(idxs(3:3:end))}} );
                x = obj.concatFeats( x, xtmp );
                for ii = 1:obj.deltasLevels
                    sf = obj.transformBlock( sf, 1, ...
                        @(b)(b(2:end,:) - b(1:end-1,:)), ...
                        @(idxs)(idxs(1:end-1)),...
                        {[num2str(ii) '.delta']} );
                    xtmp = obj.block2feat( sf, ...
                        @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                        2, @(idxs)(sort([idxs idxs])),...
                        {{'1.LMom',@(idxs)(idxs(1:2:end))},...
                         {'2.LMom',@(idxs)(idxs(2:2:end))}} );
                    x = obj.concatFeats( x, xtmp );
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

