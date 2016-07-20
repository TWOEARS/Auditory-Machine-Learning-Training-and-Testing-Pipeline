classdef AzmDistributionLabeler < LabelCreators.EnergyDependentLabeler
    % class for labeling blocks by azm of a specified source
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        angularResolution;
        nAngles;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = AzmDistributionLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'angularResolution', 15 );
            ip.addOptional( 'sourcesMinEnergy', -20 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'sourceIds', ':' );
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.EnergyDependentLabeler( ...
                                      'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                                      'sourcesMinEnergy', ip.Results.sourcesMinEnergy, ...
                                      'sourceIds', ip.Results.sourceIds );
            obj.angularResolution = ip.Results.angularResolution;
            obj.nAngles = 360 / obj.angularResolution;
            if rem( obj.nAngles, 1 ) ~= 0
                error( 'Choose a divisor of 360 as angularResolution.' );
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.angularResolution = obj.angularResolution;
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------

        function y = labelEnergeticBlock( obj, blockAnnotations )
            srcAzms = blockAnnotations.srcAzms(obj.sourceIds,:);
            srcAzmIdxs = mod( round( srcAzms / obj.angularResolution ) + 1, obj.nAngles );
            y = zeros( 1, obj.nAngles );
            y(srcAzmIdxs) = 1;
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

