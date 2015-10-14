classdef FeatureSet1BlockmeanTEST < featureCreators.Base
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        freqChannelsStatistics;
        amFreqChannels;
        deltasLevels;
        amChannels;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet1BlockmeanTEST( )
            obj = obj@featureCreators.Base( 0.5, 0.5/3, 0.75, 0.5 );
            obj.freqChannels = 16;
            obj.amFreqChannels = 8;
            obj.freqChannelsStatistics = 32;
            obj.deltasLevels = 2;
            obj.amChannels = 9;
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests{1}.name = 'amsFeatures';
            afeRequests{1}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.amFreqChannels, ...
                'ams_fbType', 'log', ...
                'ams_nFilters', obj.amChannels, ...
                'ams_lowFreqHz', 1, ...
                'ams_highFreqHz', 256' ...
                );
            afeRequests{2}.name = 'ratemap';
            afeRequests{2}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'rm_scaling', 'magnitude', ...
                'fb_nChannels', obj.freqChannels ...
                );
            afeRequests{3}.name = 'spectralFeatures';
            afeRequests{3}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.freqChannelsStatistics ...
                );
            afeRequests{4}.name = 'onsetStrength';
            afeRequests{4}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.freqChannels ...
                );
        end
        %% ----------------------------------------------------------------

        function x = makeDataPoint( obj, afeData )
        end
        %% ----------------------------------------------------------------

        function b = makeBlockFromAfe( obj, afeIdx, chIdx, func, grps, varargin )
        end
        %% ----------------------------------------------------------------

        function b = concatBlocks( obj, dim, varargin )
        end
        %% ----------------------------------------------------------------

        function b = transformBlock( obj, bl, dim, func, grp )
        end
        %% ----------------------------------------------------------------

        function b = reshapeBlock( obj, bl, varargin )
        end
        %% ----------------------------------------------------------------

        function x = block2feat( obj, b, dim, func, grps )
        end
        %% ----------------------------------------------------------------
        
        function x = constructVector( obj )
            rmR = obj.makeBlockFromAfe( 2, 1, ...
                @(a)(compressAndScale( a.Data, 0.33, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'f',@(a)(a.cfHz)} );
            rmL = obj.makeBlockFromAfe( 2, 2, ...
                @(a)(compressAndScale( a.Data, 0.33, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'f',@(a)(a.cfHz)} );
            spfR = obj.makeBlockFromAfe( 3, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'type',@(a)(a.fList)} );
            spfL = obj.makeBlockFromAfe( 3, 2, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'type',@(a)(a.fList)} );
            onsR = obj.makeBlockFromAfe( 4, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'f',@(a)(a.cfHz)} );
            onsL = obj.makeBlockFromAfe( 4, 2, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'f',@(a)(a.cfHz)} );
            xb = obj.concatBlocks( 2, rmR, rmL, spfR, spfL, onsR, onsL );
            x = obj.block2feat( xb, 2, ...
                @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                {'1.LMom','2.LMom','3.LMom'} );
            for ii = 1:obj.deltasLevels
                xb = obj.transformBlock( xb, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    {[num2str(ii) '.delta']} );
                x = [x obj.block2feat( xb, 2, ...
                    @(b)(lMomentAlongDim( b, [1,2,3,4], 1, true )), ...
                    {'1.LMom','2.LMom','3.LMom','4.LMom'} )];
            end
            modR = obj.makeBlockFromAfe( 1, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, ...
                {'t'}, {'f',@(a)(a.cfHz)}, {'mf',@(a)(a.modCfHz)} );
            modL = obj.makeBlockFromAfe( 1, 2, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, ...
                {'t'}, {'f',@(a)(a.cfHz)}, {'mf',@(a)(a.modCfHz)} );
            modR = obj.reshapeBlock( modR, size( modR, 1 ), [] );
            modL = obj.reshapeBlock( modL, size( modL, 1 ), [] );
%            modR = reshape( modR, size( modR, 1 ), size( modR, 2 ) * size( modR, 3 ) );
%            modL = reshape( modL, size( modL, 1 ), size( modL, 2 ) * size( modL, 3 ) );
            x = [x obj.block2feat( modR, 2, ...
                @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                {'1.LMom','2.LMom'} )];
            x = [x obj.block2feat( modL, 2, ...
                @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                {'1.LMom','2.LMom'} )];
            for ii = 1:obj.deltasLevels
                modR = obj.transformBlock( modR, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    {[num2str(ii) '.delta']} );
                modL = obj.transformBlock( modL, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    {[num2str(ii) '.delta']} );
                x = [x obj.block2feat( modR, 2, ...
                    @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                    {'1.LMom','2.LMom','3.LMom'} )];
                x = [x obj.block2feat( modL, 2, ...
                    @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                    {'1.LMom','2.LMom','3.LMom'} )];
            end
        end
        %% ----------------------------------------------------------------

%         function x = makeDataPoint( obj, afeData )
%             rmRL = afeData(2);
%             rmR = compressAndScale( rmRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
%             rmL = compressAndScale( rmRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
%             spfRL = afeData(3);
%             spfR = compressAndScale( spfRL{1}.Data, 0.33 );
%             spfL = compressAndScale( spfRL{2}.Data, 0.33 );
%             onsRL = afeData(4);
%             onsR = compressAndScale( onsRL{1}.Data, 0.33 );
%             onsL = compressAndScale( onsRL{2}.Data, 0.33 );
%             xBlock = [rmR, rmL, spfR, spfL, onsR, onsL];
%             x = lMomentAlongDim( xBlock, [1,2,3], 1, true );
%             for i = 1:obj.deltasLevels
%                 xBlock = xBlock(2:end,:) - xBlock(1:end-1,:);
%                 x = [x  lMomentAlongDim( xBlock, [1,2,3,4], 1, true )];
%             end
%             modRL = afeData(1);
%             modR = compressAndScale( modRL{1}.Data, 0.33 );
%             modL = compressAndScale( modRL{2}.Data, 0.33 );
%             modR = reshape( modR, size( modR, 1 ), size( modR, 2 ) * size( modR, 3 ) );
%             modL = reshape( modL, size( modL, 1 ), size( modL, 2 ) * size( modL, 3 ) );
%             x = [x lMomentAlongDim( modR, [1,2], 1, true )];
%             x = [x lMomentAlongDim( modL, [1,2], 1, true )];
%             for i = 1:obj.deltasLevels
%                 modR = modR(2:end,:) - modR(1:end-1,:);
%                 modL = modL(2:end,:) - modL(1:end-1,:);
%                 x = [x lMomentAlongDim( modR, [1,2,3], 1, true )];
%                 x = [x lMomentAlongDim( modL, [1,2,3], 1, true )];
%             end
%         end
%         %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.freqChannels = obj.freqChannels;
            outputDeps.amFreqChannels = obj.amFreqChannels;
            outputDeps.freqChannelsStatistics = obj.freqChannelsStatistics;
            outputDeps.amChannels = obj.amChannels;
            outputDeps.deltasLevels = obj.deltasLevels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 6;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

