classdef RatemapPlusDeltasBlockmean < FeatureProcInterface
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        deltasLevels;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = RatemapPlusDeltasBlockmean()
            obj = obj@FeatureProcInterface();
            obj.freqChannels = 16;
            obj.deltasLevels = 1;
        end
        
        %%-----------------------------------------------------------------

        function wp2Requests = getWp2Requests( obj )
            wp2Requests{1}.name = 'ratemap_magnitude';
            wp2Requests{1}.params = genParStruct( ...
                'nChannels', obj.freqChannels, ...
                'rm_scaling', 'magnitude' ...
                );
        end

        %%-----------------------------------------------------------------

        function x = makeDataPoint( obj, wp2data )
            rmRL = wp2data('ratemap_magnitude');
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
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
        
        function rm = compressAndScale( obj, rm )
            rm = rm.^0.33; %cuberoot compression
            rmMedian = median( rm(rm>0.01) );
            if isnan( rmMedian ), scale = 1;
            else scale = 0.5 / rmMedian; end;
            rm = rm .* repmat( scale, size( rm ) );
        end
        
    end
    
end

