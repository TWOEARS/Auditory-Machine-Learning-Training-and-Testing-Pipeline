classdef GlmNetModelSelectTrainer < ModelTrainers.HpsTrainer & Parameterized
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = {?Parameterized})
        hpsAlphaRange;
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = GlmNetModelSelectTrainer( varargin )
            pds{1} = struct( 'name', 'hpsAlphaRange', ...
                             'default', [0 1], ...
                             'valFun', @(x)(isfloat(x) && length(x)==2 && x(1) < x(2)) );
            obj = obj@Parameterized( pds );
            obj = obj@ModelTrainers.HpsTrainer( varargin{:} );
            obj.setParameters( true, ...
                'buildCoreTrainer', @GlmNetLambdaSelectTrainer, ...
                'hpsCoreTrainerParams', {'cvFolds', 2,}, ...
                 varargin{:} );
            obj.setParameters( false, 'finalCoreTrainerParams', {'cvFolds', 2,} );
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function hpsSets = getHpsGridSearchSets( obj )
            hpsAlphas = linspace( obj.hpsAlphaRange(1), ...
                                  obj.hpsAlphaRange(2), ...
                                  obj.hpsSearchBudget );
            [aGrid] = ndgrid( hpsAlphas );
            hpsSets = [aGrid(:)];
            hpsSets = unique( hpsSets, 'rows' );
            hpsSets = cell2struct( num2cell(hpsSets), {'alpha'}, 2 );
        end
        %% -------------------------------------------------------------------------------
        
        function refineGridTrainer( obj, hps )
            best3LogMean = @(fn)(mean( log10( [hps.params(end-2:end).(fn)] ) ));
            aRefinedRange = 10.^getCenteredHalfRange( ...
                                        log10(obj.hpsAlphaRange), best3LogMean('alpha') );
            obj.setParameters( false, 'hpsAlphaRange', aRefinedRange );
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = private)
        
    end
    
end