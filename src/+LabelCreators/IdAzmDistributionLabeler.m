classdef IdAzmDistributionLabeler < LabelCreators.AzmDistributionLabeler
    % class for labeling blocks by azm of a specified source
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        types;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdAzmDistributionLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'angularResolution', 5 );
            ip.addOptional( 'sourcesMinEnergy', -20 );
            ip.addOptional( 'labelBlockSize_s', [] );
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.AzmDistributionLabeler( ...
                                      'angularResolution', ip.Results.angularResolution, ...
                                      'labelBlockSize_s', ip.Results.labelBlockSize_s, ...
                                      'sourcesMinEnergy', ip.Results.sourcesMinEnergy);
            obj.types = ip.Results.types;
        end
        %% -------------------------------------------------------------------------------
        
        function y = labelEnergeticBlock( obj, blockAnnotations )
            srcAzms = blockAnnotations.srcAzms(obj.sourceIds,:);
            srcAzmIdxs = mod( round( srcAzms / obj.angularResolution ) + 1, obj.nAngles );
            y = zeros( numel(obj.types), obj.nAngles+1 );
            y(:, end) = 1; % set void bin to 1
            typeAtSrc = blockAnnotations.srcType.srcType(:,1);
            srcIdx = blockAnnotations.srcType.srcType(:,2);
            for ii = 1:numel(srcIdx)
                isType = cellfun(@(v) any(strcmp([v{:}], typeAtSrc(ii))), ...
                    obj.types, 'un', false);
                typeIdx = find(not(cellfun('isempty', isType)));
                if ~isempty(typeIdx)
                    y(typeIdx, srcAzmIdxs(srcIdx{ii})) = 1;
                    y(typeIdx, end) = 0; % clear void bin
                end
            end
            y = reshape(y, 1, numel(obj.types) * (obj.nAngles + 1));
        end
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        %% -----------------------------------------------------------------------------------
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.angularResolution = obj.angularResolution;
            outputDeps.types = obj.types;
            outputDeps.v = 1;
        end   
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

