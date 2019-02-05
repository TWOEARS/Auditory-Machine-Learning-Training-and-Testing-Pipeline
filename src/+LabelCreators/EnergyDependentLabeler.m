classdef EnergyDependentLabeler < LabelCreators.Base
    % abstract class for labeling blocks that exhibit enough energy in specified sources
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        sourcesMinEnergy;
        sourceIds;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
        [y, ysi] = labelEnergeticBlock( obj, blockAnnotations )
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = EnergyDependentLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'sourcesMinEnergy', -20 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'sourceIds', 1 );
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.Base( 'labelBlockSize_s', ip.Results.labelBlockSize_s );
            obj.sourcesMinEnergy = ip.Results.sourcesMinEnergy;
            obj.sourceIds = ip.Results.sourceIds;
        end
        %% -------------------------------------------------------------------------------

        function [y, ysi] = label( obj, blockAnnotations )
            rejectBlock = LabelCreators.EnergyDependentLabeler.isEnergyTooLow( ...
                                  blockAnnotations, obj.sourceIds, obj.sourcesMinEnergy );
            if rejectBlock
                y = NaN;
                ysi = {};
            else
                [y, ysi] = obj.labelEnergeticBlock( blockAnnotations );
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps = getInternOutputDependencies@LabelCreators.Base( obj );
            outputDeps.sourcesMinEnergy = obj.sourcesMinEnergy;
            outputDeps.sourceIds = obj.sourceIds;
            outputDeps.v = 2;
        end
        %% -------------------------------------------------------------------------------
                
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
        function eTooLow = isEnergyTooLow( blockAnnots, sourceIds, sourcesMinEnergy )
            sourceIds(sourceIds > size( blockAnnots.globalSrcEnergy, 2 )) = [];
            srcsGlobalRefEnergyMeanChannel = cellfun( @(c)(sum(10.^(c./10)) ./ 2 ), ...
                                                      blockAnnots.globalSrcEnergy(sourceIds) );
            srcsGlobalRefEnergyMeanChannel_db = 10 * log10( srcsGlobalRefEnergyMeanChannel );
            eTooLow = sum( log( sourcesMinEnergy ./ srcsGlobalRefEnergyMeanChannel_db ) ) < 0;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

