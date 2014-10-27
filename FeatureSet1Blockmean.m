classdef FeatureSet1Blockmean < FeatureProcInterface
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        deltasLevels;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet1Blockmean( )
            obj = obj@FeatureProcInterface();
            obj.freqChannels = 16;
            obj.deltasLevels = 1;
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests{1}.name = 'modulation';
            afeRequests{1}.params = genParStruct( ...
                'nChannels', obj.freqChannels, ...
                'am_type', 'filter' ...
                );
            afeRequests{2}.name = 'ratemap_magnitude';
            afeRequests{2}.params = genParStruct( ...
                'nChannels', obj.freqChannels ...
                );
            afeRequests{3}.name = 'spec_features';
            afeRequests{3}.params = genParStruct( ...
                'nChannels', obj.freqChannels ...
                );
            afeRequests{4}.name = 'onset_strength';
            afeRequests{4}.params = genParStruct( ...
                'nChannels', obj.freqChannels ...
                );
        end
        %% ----------------------------------------------------------------

        function x = makeDataPoint( obj, afeData )
            rmRL = afeData('ratemap_magnitude');
            rmR = compressAndScale( rmRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rmL = compressAndScale( rmRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            rm = 0.5 * rmR + 0.5 * rmL;
            spfRL = afeData('spec_features');
            spfR = compressAndScale( spfRL{1}.Data, 0.33, @(x)(median( abs(x(abs(x)>0.01)) )), 2 );
            spfL = compressAndScale( spfRL{2}.Data, 0.33, @(x)(median( abs(x(abs(x)>0.01)) )), 2 );
            spf = 0.5 * spfL + 0.5 * spfR;
            onsRL = afeData('onset_strength');
            onsR = compressAndScale( onsRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            onsL = compressAndScale( onsRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            ons = 0.5 * onsR + 0.5 * onsL;
            xBlock = [rm, spf, ons];
            x = [mean( xBlock, 1 )  std( xBlock, 0, 1 )];
            for i = 1:obj.deltasLevels
                xBlock = xBlock(2:end,:) - xBlock(1:end-1,:);
                x = [x  mean( xBlock, 1 )  std( xBlock, 0, 1 )];
            end
            modRL = afeData('modulation');
            modR = compressAndScale( modRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            modL = compressAndScale( modRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
            mod = 0.5 * modR + 0.5 * modL;
            mod = reshape( mod, size( mod, 1 ), size( mod, 2 ) * size( mod, 3 ) );
            x = [x mean( mod, 1 )  std( mod, 0, 1 )];
            for i = 1:obj.deltasLevels
                mod = mod(2:end,:) - mod(1:end-1,:);
                x = [x  mean( mod, 1 )  std( mod, 0, 1 )];
            end
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.freqChannels = obj.freqChannels;
            outputDeps.deltasLevels = obj.deltasLevels;
            classInfo = metaclass( obj );
            classname = classInfo.Name;
            outputDeps.featureProc = classname;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

