classdef (Abstract) Base < handle
    % Base Abstract ModelTrainers Base class ?
    %
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainSet;
        testSet;
        positiveClass;
    end
    
    properties (SetAccess = {?modelTrainers.Base, ?Parameterized})
        performanceMeasure;
        maxDataSize;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function setData( obj, trainSet, testSet )
            obj.trainSet = trainSet;
            if ~exist( 'testSet', 'var' ), testSet = []; end
            obj.testSet = testSet;
        end
        %% ----------------------------------------------------------------
        
        function setPositiveClass( obj, modelName )
            if ~isa( modelName, 'char' ), error( 'modelName must be a string.' ); end
            obj.positiveClass = modelName;
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
            if ~isa( model, 'models.Base' )
                error( 'giveTrainedModel must produce an models.Base object.' );
            end
            model.featureMask = modelTrainers.Base.featureMask;
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
            if nargin < 2, getDatapointInfo = 'noInfo'; end
            verboseFprintf( obj, 'Applying model to test set...\n' );
            model = obj.getModel();
            model.verbose( obj.verbose );
            performance = models.Base.getPerformance( ...
                model, obj.testSet, obj.positiveClass, obj.performanceMeasure, ...
                obj.maxDataSize, true, getDatapointInfo );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            [x,y] = obj.getPermutedTrainingData();
            if any( any( isnan( x ) ) ) || any( any( isinf( x ) ) ) 
                warning( 'There are NaNs or INFs in the data!' );
            end
            if numel( y ) > obj.maxDataSize
                if modelTrainers.Base.balMaxData
                    nPos = min( int32( obj.maxDataSize/2 ), sum( y == +1 ) );
                    nNeg = obj.maxDataSize - nPos;
                    posIdxs = find( y == +1 );
                    posIdxs = posIdxs(randperm(numel(posIdxs)));
                    posIdxs(1:nPos) = [];
                    negIdxs = find( y == -1 );
                    negIdxs = negIdxs(randperm(numel(negIdxs)));
                    negIdxs(1:nNeg) = [];
                    x([posIdxs; negIdxs],:) = [];
                    y([posIdxs; negIdxs]) = [];
                else
                    x(obj.maxDataSize+1:end,:) = [];
                    y(obj.maxDataSize+1:end) = [];
                end
            end
            obj.buildModel( x, y );
        end
        %% ----------------------------------------------------------------

        function [x,y] = getPermutedTrainingData( obj )
            x = obj.trainSet(:,:,'x');
            if isempty( x )
                warning( 'There is no data to train the model.' ); 
                y = [];
            else
                y = obj.trainSet(:,:,'y',obj.positiveClass);
            end
            % remove samples with fuzzy labels
            x(y==0,:) = [];
            y(y==0) = [];
            % apply the mask
            fmask = modelTrainers.Base.featureMask;
            if ~isempty( fmask )
                p_feat = size( x, 2 );
                p_mask = size( modelTrainers.Base.featureMask, 1 );
                fmask = fmask( 1 : min( p_feat, p_mask ) );
                x = x(:,fmask);
            end
            % permute data
            permutationIdxs = randperm( length( y ) );
            x = x(permutationIdxs,:);
            y = y(permutationIdxs);
        end
        %% ----------------------------------------------------------------

        
    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        buildModel( obj, x, y )
    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        model = giveTrainedModel( obj )
    end
    
    %% --------------------------------------------------------------------
    methods (Static)

        function b = balMaxData( setNewValue, newValue )
            persistent balMaxD;
            if isempty( balMaxD )
                balMaxD = false;
            end
            if nargin > 0  &&  setNewValue
                balMaxD = newValue;
            end
            b = balMaxD;
        end
        
        function fm = featureMask( setNewMask, newmask )
            % Set/Reset the featureMask and return it.
            %   featureMask() reset the featurMask
            %   featureMask( setNewMask, newmask ) set the feature mask to 
            %       newmask on the condition that setNewMask is true
            persistent featureMask;
            if ~isempty( featureMask )
                featureMask = []; % reset the feature mask
            end
            if nargin > 0  &&  setNewMask
                if ~isempty( newmask ) && size( newmask, 2 ) ~= 1, newmask = newmask'; end;
                if ~islogical( newmask ), newmask = logical( newmask ); end
                featureMask = newmask;
            end
            fm = featureMask;
        end
        
    end

end

