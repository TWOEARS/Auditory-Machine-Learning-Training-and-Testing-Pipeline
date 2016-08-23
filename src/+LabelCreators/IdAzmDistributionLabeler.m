classdef IdAzmDistributionLabeler < LabelCreators.AzmDistributionLabeler & LabelCreators.MultiEventTypeLabeler
    % class for labeling blocks by azm distributions of a specified set of
    % types
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        function obj = IdAzmDistributionLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'labelBlockSize_s', [] );
            % AzmDistributionLabeler parameters
            ip.addOptional( 'angularResolution', 5 );
            ip.addOptional( 'sourcesMinEnergy', -20 );
            % MultiEventTypeLabeler parameters
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'maxNegBlockToEventRatio', 0 );
            ip.parse( varargin{:} );
            obj@LabelCreators.AzmDistributionLabeler( ...
                                      'angularResolution', ip.Results.angularResolution, ...
                                      'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                                      'sourcesMinEnergy', ip.Results.sourcesMinEnergy);
            obj@LabelCreators.MultiEventTypeLabeler( ...
                                      'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                                      'minBlockToEventRatio', ip.Results.minBlockToEventRatio, ...
                                      'maxNegBlockToEventRatio', ip.Results.maxNegBlockToEventRatio, ...
                                      'types', ip.Results.types);
        end
        
        %% -------------------------------------------------------------------------------
        function y = labelEnergeticBlock( obj, blockAnnotations )
            
            [activeTypes, ~, activeSrcIdxs] = getActiveTypes( obj, blockAnnotations );
            srcAzms = blockAnnotations.srcAzms(obj.sourceIds,:);
            srcAzmIdxs = mod( round( srcAzms / obj.angularResolution ) + 1, obj.nAngles );
            % initialize output
            y = zeros( numel(obj.types), obj.nAngles+1 );
            y(:, end) = ~activeTypes'; % set void bin to inverse of active types
            % mark azimuths of active types for each source
            for activeTypeIdx = find(activeTypes)
                activeSrcs = activeSrcIdxs{activeTypeIdx};
                y(activeTypeIdx, srcAzmIdxs(activeSrcs)) = 1;
            end
            y = reshape(y, 1, numel(obj.types) * (obj.nAngles + 1));
        end
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        function y = label( obj, blockAnnotations )
            y = label@LabelCreators.EnergyDependentLabeler(obj, blockAnnotations);
        end
        
        %% -----------------------------------------------------------------------------------
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps = getLabelInternOutputDependencies@LabelCreators.AzmDistributionLabeler(obj);
            outputDepsM = getLabelInternOutputDependencies@LabelCreators.MultiEventTypeLabeler(obj);
            fieldsNew = fieldnames(outputDepsM);
            for ii = 1:numel(fieldsNew)
                outputDeps.(fieldsNew{ii}) = outputDepsM.(fieldsNew{ii});
            end
            outputDeps.v = 1;
        end
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

