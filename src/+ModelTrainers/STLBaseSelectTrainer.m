classdef STLBaseSelectTrainer < ModelTrainers.HpsTrainer & Parameterized
    % STLBaseSelectTrainer  HpsTrainer to select an optimal sparse coding
    %                       base for self-taught learning 
    %   Implements a hyperparameter search to find an optimal base for STL 
    %   (self-taught learning). This trainer will do a k-fold cv to choose
    %   the optimal base given a specified classfier (trainer).
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        hpsBases; % bases for STL 
        hpsBetaRange; % range of sparsity factors for feature extraction
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = STLBaseSelectTrainer( varargin )
            pds{1} = struct( 'name', 'hpsBases', ...
                             'default', {}, ...
                             'valFun', @(x)(iscell(x) && ~isempty(x) && all(cellfun(@ismatrix, x))) );
            
            pds{2} = struct( 'name', 'hpsBetaRange', ...
                             'default', [0.4 1], ...
                             'valFun', @(x)(isfloat(x) && length(x)==2 && x(1) < x(2)) );
                         
                                   
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.HpsTrainer( varargin{:} );
            
            obj.setParameters( true, ...
                'buildCoreTrainer', @ModelTrainers.STLTrainerDecorator, ...
                varargin{:} );
            
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function hpsSets = getHpsGridSearchSets( obj )
            hpsBetas = linspace( obj.hpsBetaRange(1), ...
                                  obj.hpsBetaRange(2), ...
                                  obj.hpsSearchBudget );
            betaGrid = repmat(hpsBetas, length(obj.hpsBases), 1);
            betaGrid = num2cell(betaGrid(:));
            baseGrid = repmat(obj.hpsBases, obj.hpsSearchBudget, 1);
            hpsSets = [baseGrid(:), betaGrid(:)];
            hpsSets = cell2struct( hpsSets, {'base', 'beta'}, 2 );
        end
        %% -------------------------------------------------------------------------------
        
        function refinedHpsTrainer = refineGridTrainer( obj, hps )
            error('refinedHpsTrainer is not implemented by STLBaseSelectTrainer.')
        end
        
        %% -------------------------------------------------------------------------------
        
    end
        
end