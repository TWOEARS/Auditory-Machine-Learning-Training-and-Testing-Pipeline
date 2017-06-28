classdef SparseCodingSelectTrainer < ModelTrainers.HpsTrainer & Parameterized
    % SparseCodingSelectTrainer trainer for a SparseCodingModel
    %   Implements sparse coding for a given input to fit a base with 
    %   sparse activations. This trainer will do a k-fold 
    %   cross-validation to choose the best sparsity factor beta as well 
    %   as the dimension of the base.
    %% --------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        hpsBetas;            % vector of sparsity factors
        hpsNumBasesRange;    % range of dim of base
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = SparseCodingSelectTrainer( varargin )
            pds{1} = struct( 'name', 'hpsBetas', ...
                             'default', [0.4 0.6 0.8 1], ...
                             'valFun', @(x)(isfloat(x) && isvector(x)) );
                         
            pds{2} = struct( 'name', 'hpsNumBasesRange', ...
                             'default', [100 1000], ...
                             'valFun', @(x) ( all(mod(x,1) == 0) && length(x)==2 && x(1) < x(2) ) );
                       
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.HpsTrainer( varargin{:} );
            
            % skip training with best trainer
            obj.trainWithBestHps = false;
            
            obj.setParameters( true, ...
                'buildCoreTrainer', @ModelTrainers.SparseCodingTrainer, ...
                'hpsCoreTrainerParams', {'saveModelDir', './scSelect'}, ...
                varargin{:} );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function hpsSets = getHpsGridSearchSets( obj )
            
            % number of bases has to be integer                  
            hpsNumBases = floor( logspace( log10(obj.hpsNumBasesRange(1)), ...
                                  log10(obj.hpsNumBasesRange(2)), ...
                                  obj.hpsSearchBudget ) );
                              
            [betaGrid, numBasesGrid] = ndgrid( obj.hpsBetas, hpsNumBases );
            hpsSets = [betaGrid(:), numBasesGrid(:)];
            hpsSets = unique( hpsSets, 'rows' );
            hpsSets = cell2struct( num2cell(hpsSets), {'beta', 'num_bases'}, 2 );
        end
        %% -------------------------------------------------------------------------------
        
        function refinedHpsTrainer = refineGridTrainer( obj, hps )
            error('refinedHpsTrainer is not implemented in SparseCodingSelectTrainer.')
        end
        
        %% -------------------------------------------------------------------------------
        
    end
        
end