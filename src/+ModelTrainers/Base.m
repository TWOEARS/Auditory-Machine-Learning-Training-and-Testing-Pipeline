classdef (Abstract) Base < matlab.mixin.Copyable & Parameterized
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainSet;
        testSet;
    end
    
    properties (SetAccess = {?ModelTrainers.Base, ?Parameterized})
        performanceMeasure;
        maxDataSize;
        maxTestDataSize;
        dataSelector;
        importanceWeighter;
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)

        function cpObj = copyElement( obj )
            cpObj = copyElement@matlab.mixin.Copyable( obj );
            cpObj.dataSelector = copy( obj.dataSelector );
            cpObj.importanceWeighter = copy( obj.importanceWeighter );
        end
        %% ----------------------------------------------------------------
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = Base( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @PerformanceMeasures.BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{3} = struct( 'name', 'maxTestDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{4} = struct( 'name', 'dataSelector', ...
                             'default', DataSelectors.IgnorantSelector(), ...
                             'valFun', @(x)(isa( x, 'DataSelectors.Base') ) );
            pds{5} = struct( 'name', 'importanceWeighter', ...
                             'default', ImportanceWeighters.IgnorantWeighter(), ...
                             'valFun', @(x)(isa( x, 'ImportanceWeighters.Base') ) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------
        
        function setData( obj, trainSet, testSet )
            obj.trainSet = trainSet;
            if ~exist( 'testSet', 'var' ), testSet = []; end
            obj.testSet = testSet;
        end
        %% ----------------------------------------------------------------
        
        function setPerformanceMeasure( obj, newPerformanceMeasure )
            if ~isa( newPerformanceMeasure, 'function_handle' )
                error( ['newPerformanceMeasure must be a function handle pointing ', ...
                        'to the constructor of a PerformanceMeasure interface.'] );
            end
            obj.performanceMeasure = newPerformanceMeasure;
        end
        %% ----------------------------------------------------------------
        
        function model = getModel( obj )
            model = obj.giveTrainedModel();
            if ~isa( model, 'Models.Base' )
                error( 'giveTrainedModel must produce an Models.Base object.' );
            end
            model.featureMask = ModelTrainers.Base.featureMask;
        end
        %% -------------------------------------------------------------------------------
        
        function v = verbose( obj, newV )
            persistent verb;    % faking a static property
            if isempty( verb ), verb = false; end
            if nargin > 1
                if islogical( newV )
                    verb = newV;
                elseif ischar( newV ) && any( strcmpi( newV, {'true','on','set'} ) )
                    verb = true;
                elseif ischar( newV ) && any( strcmpi( newV, {'false','off','unset'} ) )
                    verb = false;
                else
                    error( 'wrong datatype for newV.' );
                end
            end
            v = verb;
        end
        %% -------------------------------------------------------------------------------
        
        function performance = getPerformance( obj, getDatapointInfo )
            if nargin < 2, getDatapointInfo = false; end
            verboseFprintf( obj, '\nApplying model to test set...\n' );
            model = obj.getModel();
            model.verbose( obj.verbose );
            performance = Models.Base.getPerformance( ...
                model, obj.testSet, obj.performanceMeasure, ...
                obj.maxTestDataSize, obj.dataSelector, obj.importanceWeighter, ...
                getDatapointInfo );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            [x,y,iw,verbOutput] = ModelTrainers.Base.getSelectedData( ...
                                               obj.trainSet, obj.maxDataSize, ...
                                               obj.dataSelector, obj.importanceWeighter );
            verboseFprintf( obj, verbOutput );
            if numel( unique( y ) ) == 1
                fprintf( 'Only one unique value for y!\n' );
            end
            tic;
            obj.buildModel( x, y, iw );
            trainTime = toc;
            model = obj.giveTrainedModel();
            model.trainTime = trainTime;
            model.trainsetSize = size( x );
        end
        %% ----------------------------------------------------------------
        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        buildModel( obj, x, y, iw )
    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        model = giveTrainedModel( obj )
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    
        function [x,y,iw,verbOutput,ba,sampleIds] = getSelectedData( dataset, ...
                                                                     maxDataSize, ...
                                                                     dataSelector, ...
                                                                     importanceWeighter,...
                                                                     permuteData, ...
                                                                     applyFmask, ...
                                                                     loadBAs )
            y = getDataHelper( dataset, 'y' );
            verbOutput = '';
            if isempty( y )
                x = [];
                iw = [];
                return;
            end
            x = getDataHelper( dataset, 'x' );
            sampleIds = 1 : size( x, 1 );
            if nargout >= 5 && (nargin < 7 || loadBAs)
                ba = getDataHelper( dataset, 'blockAnnotations' );
            elseif nargout >= 5 && nargin >= 7 && ~loadBAs
                ba = struct.empty;
            end
            nanXidxs = any( isnan( x ), 2 );
            infXidxs = any( isinf( x ), 2 );
            if any( nanXidxs ) || any( infXidxs ) 
                warning( 'There are NaNs or INFs in the data -- throwing those vectors away!' );
                x(nanXidxs | infXidxs,:) = [];
                y(nanXidxs | infXidxs,:) = [];
                if nargout >= 5 && ~isempty( ba )
                    ba(nanXidxs | infXidxs) = [];
                end
                sampleIds(nanXidxs | infXidxs) = [];
            end
            if nargin < 3  || isempty( dataSelector )
                dataSelector = DataSelectors.IgnorantSelector(); 
            end
            dataSelector.connectData( dataset );
            if numel( sampleIds ) > maxDataSize
                selectFilter = dataSelector.getDataSelection( sampleIds, maxDataSize );
                verbOutput = dataSelector.verboseOutput;
                x = x(selectFilter,:);
                y = y(selectFilter,:);
                if nargout >= 5 && ~isempty( ba )
                    ba = ba(selectFilter);
                end
                sampleIds = sampleIds(selectFilter);
            end
            dataSelector.connectData( [] );
            % apply feature mask, if set
            if nargin < 6 || applyFmask
                fmask = ModelTrainers.Base.featureMask;
                if ~isempty( fmask )
                    nFeat = size( x, 2 );
                    nMask = numel( ModelTrainers.Base.featureMask );
                    assert( nFeat == nMask );
                    x = x(:,fmask);
                end
            end
            if nargin < 5 || permuteData
                permIds = randperm( size( y, 1 ) )';
                x = x(permIds,:);
                y = y(permIds,:);
                if nargout >= 5 && ~isempty( ba )
                    ba = ba(permIds);
                end
                sampleIds = sampleIds(permIds);
            end
            if ~isempty( importanceWeighter )
                importanceWeighter.connectData( dataset );
                iw = importanceWeighter.getImportanceWeights( sampleIds );
                verbOutput = [verbOutput importanceWeighter.verboseOutput];
                importanceWeighter.connectData( [] );
            else
                iw = ones( size( x, 1 ), 1 );
            end
        end
        %% ----------------------------------------------------------------
        
        function fm = featureMask( setNewMask, newmask )
            % Set/Reset the featureMask and return it.
            %   featureMask() reset the featurMask
            %   featureMask( setNewMask, newmask ) set the feature mask to 
            %       newmask on the condition that setNewMask is true
            persistent featureMask;
            if isempty( featureMask )
                featureMask = [];
            end
            if nargin > 0  &&  setNewMask
                if ~isempty( newmask ) && size( newmask, 2 ) ~= 1, newmask = newmask'; end;
                if ~islogical( newmask ), newmask = logical( newmask ); end
                featureMask = newmask;
            end
            fm = featureMask;
        end
        %% ----------------------------------------------------------------
        
    end

end

