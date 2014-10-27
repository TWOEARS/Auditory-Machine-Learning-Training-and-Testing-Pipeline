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
            rmR = rmRL{1}.Data;
            rmL = rmRL{2}.Data;
            rmR = obj.compressAndScale( rmR );
            rmL = obj.compressAndScale( rmL );
            rm = 0.5 * rmR + 0.5 * rmL;
            x = [mean( rm, 1 )  std( rm, 0, 1 )];
            for i = 1:obj.deltasLevels
                rm = rm(2:end,:) - rm(1:end-1,:);
                x = [x  mean( rm, 1 )  std( rm, 0, 1 )];
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
        
        function rm = compressAndScale( obj, rm )
            rm = rm.^0.33; %cuberoot compression
            rmMedian = median( rm(rm>0.01) );
            if isnan( rmMedian ), scale = 1;
            else scale = 0.5 / rmMedian; end;
            rm = rm .* repmat( scale, size( rm ) );
        end
        %% ----------------------------------------------------------------
        
    end
    
end

