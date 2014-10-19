classdef RatemapPlusDeltasBlockmean < IdFeatureProcInterface

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        deltasLevels;
        blockSize_s;
        shiftSize_s;
        minBlockToEventRatio;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = RatemapPlusDeltasBlockmean()
            obj = obj@IdFeatureProcInterface();
            obj.freqChannels = 16;
            obj.deltasLevels = 1;
            obj.blockSize_s = 0.5;
            obj.shiftSize_s = 0.25;
            obj.minBlockToEventRatio = 0.5;
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

        function run( obj, idTrainData )
            fprintf( 'feature creation' );
            idTrainData.featuresHash = obj.getHash();
            featFileNameExt = ...
                ['.' idTrainData.wp1Hash ...
                 '.' idTrainData.wp2Hash ...
                 '.' idTrainData.featuresHash '.features.mat'];
            for trainFile = idTrainData(:)'
                fprintf( '\n.' );
                featuresFileName = [which(trainFile.wavFileName) featFileNameExt];
                if exist( featuresFileName, 'file' ), continue; end
                wp2FileNameExt = ['.' idTrainData.wp1Hash '.' idTrainData.wp2Hash '.wp2.mat'];
                wp2FileName = [which(trainFile.wavFileName) wp2FileNameExt];
                x = obj.makeFeatures( wp2FileName );
                wp1FileNameExt = ['.' idTrainData.wp1Hash '.wp1.mat'];
                wp1FileName = [which(trainFile.wavFileName) wp1FileNameExt];
                y = obj.makeLabels( wp1FileName );
                save( featuresFileName, 'x', 'y' );
            end
            fprintf( ';\n' );
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
end

