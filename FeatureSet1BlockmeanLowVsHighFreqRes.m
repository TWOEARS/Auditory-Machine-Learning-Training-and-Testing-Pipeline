classdef FeatureSet1BlockmeanLowVsHighFreqRes < IdFeatureProc
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
        
        function obj = FeatureSet1BlockmeanLowVsHighFreqRes( )
            obj = obj@IdFeatureProc( 0.5, 0.5/3, 0.5, 0.5 );
            obj.freqChannels = 8;
            obj.amFreqChannels = 8;
            obj.deltasLevels = 1;
            obj.amChannels = 4;
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests{1}.name = 'modulation';
            afeRequests{1}.params = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'nChannels', obj.amFreqChannels, ...
                'am_type', 'filter', ...
                'am_nFilters', obj.amChannels ...
                );
            afeRequests{2}.name = 'ratemap_magnitude';
            afeRequests{2}.params = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'rm_scaling', 'magnitude', ...
                'nChannels', obj.freqChannels ...
                );
            afeRequests{4}.name = 'onset_strength';
            afeRequests{4}.params = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'nChannels', obj.freqChannels ...
                );
            afeRequests{5}.name = 'modulation';
            afeRequests{5}.params = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'nChannels', obj.amFreqChannels*2, ...
                'am_type', 'filter', ...
                'am_nFilters', obj.amChannels ...
                );
            afeRequests{6}.name = 'ratemap_magnitude';
            afeRequests{6}.params = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'rm_scaling', 'magnitude', ...
                'nChannels', obj.freqChannels*4 ...
                );
            afeRequests{8}.name = 'onset_strength';
            afeRequests{8}.params = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'nChannels', obj.freqChannels*4 ...
                );
        end
        %% ----------------------------------------------------------------

        function x = makeDataPoint( obj, afeData )
            rmRL = afeData('ratemap_magnitude');
            rmR = compressAndScale( rmRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rmL = compressAndScale( rmRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rm = 0.5 * rmR + 0.5 * rmL;
            spfRL = afeData('spec_features');
            spfR = compressAndScale( spfRL{1}.Data, 0.33 );
            spfL = compressAndScale( spfRL{2}.Data, 0.33 );
            spf = 0.5 * spfL + 0.5 * spfR;
            onsRL = afeData('onset_strength');
            onsR = compressAndScale( onsRL{1}.Data, 0.33 );
            onsL = compressAndScale( onsRL{2}.Data, 0.33 );
            ons = 0.5 * onsR + 0.5 * onsL;
            xBlock = [rm, spf, ons];
            x = lMomentAlongDim( xBlock, [1,2,3], 1 );
            for i = 1:obj.deltasLevels
                xBlock = xBlock(2:end,:) - xBlock(1:end-1,:);
                x = [x  lMomentAlongDim( xBlock, [2,3,4], 1 )];
            end
            modRL = afeData('modulation');
            modR = compressAndScale( modRL{1}.Data, 0.33 );
            modL = compressAndScale( modRL{2}.Data, 0.33 );
            mod = 0.5 * modR + 0.5 * modL;
            mod = reshape( mod, size( mod, 1 ), size( mod, 2 ) * size( mod, 3 ) );
            x = [x lMomentAlongDim( mod, [1,2], 1 )];
            for i = 1:obj.deltasLevels
                mod = mod(2:end,:) - mod(1:end-1,:);
                x = [x lMomentAlongDim( mod, [2,3], 1 )];
            end
            
            rmRL = afeData('ratemap_magnitude');
            rmR = compressAndScale( rmRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rmL = compressAndScale( rmRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rm = 0.5 * rmR + 0.5 * rmL;
            spfRL = afeData('spec_features');
            spfR = compressAndScale( spfRL{1}.Data, 0.33 );
            spfL = compressAndScale( spfRL{2}.Data, 0.33 );
            spf = 0.5 * spfL + 0.5 * spfR;
            onsRL = afeData('onset_strength');
            onsR = compressAndScale( onsRL{1}.Data, 0.33 );
            onsL = compressAndScale( onsRL{2}.Data, 0.33 );
            ons = 0.5 * onsR + 0.5 * onsL;
            xBlock = [rm, spf, ons];
            x = [x momentsAlongDim( xBlock, [1,2,3], 1 )];
            for i = 1:obj.deltasLevels
                xBlock = xBlock(2:end,:) - xBlock(1:end-1,:);
                x = [x  momentsAlongDim( xBlock, [2,3,4], 1 )];
            end
            modRL = afeData('modulation');
            modR = compressAndScale( modRL{1}.Data, 0.33 );
            modL = compressAndScale( modRL{2}.Data, 0.33 );
            mod = 0.5 * modR + 0.5 * modL;
            mod = reshape( mod, size( mod, 1 ), size( mod, 2 ) * size( mod, 3 ) );
            x = [x momentsAlongDim( mod, [1,2], 1 )];
            for i = 1:obj.deltasLevels
                mod = mod(2:end,:) - mod(1:end-1,:);
                x = [x momentsAlongDim( mod, [2,3], 1 )];
            end
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.freqChannels = obj.freqChannels;
            outputDeps.amFreqChannels = obj.amFreqChannels;
            outputDeps.freqChannelsStatistics = obj.freqChannelsStatistics;
            outputDeps.amChannels = obj.amChannels;
            outputDeps.deltasLevels = obj.deltasLevels;
            classInfo = metaclass( obj );
            classname = classInfo.Name;
            outputDeps.featureProc = classname;
            outputDeps.v = 3;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

