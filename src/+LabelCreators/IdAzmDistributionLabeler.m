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
            y(:, end) = 1; % set void bin to 1
            % mark azimuths of axtive types for each source
            typeAtSrc = blockAnnotations.srcType.srcType(:,1);
            srcIdxs = blockAnnotations.srcType.srcType(:,2);
            for ii = 1:numel(srcIdxs)
                isType = cellfun(@(v) any(strcmp([v{:}], typeAtSrc(ii))), ...
                    obj.types, 'un', false);
                typeIdx = find(cellfun(@(v) isequal(v, 1), isType));
                if ~isempty(typeIdx)
                    % block events that don't qualify as active
                    if activeTypes(typeIdx) && isequal(activeSrcIdxs(typeIdx), srcIdxs(ii))
                        y(typeIdx, srcAzmIdxs(srcIdxs{ii})) = 1;
                        y(typeIdx, end) = 0; % clear void bin
                    end
                end
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

        

