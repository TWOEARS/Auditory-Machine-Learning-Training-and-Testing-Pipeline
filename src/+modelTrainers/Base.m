classdef (Abstract) Base < handle
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        trainSet;
        testSet;
        positiveClass;
        featureMask = []; %negative mask for the columns of the feature mx
    end
    
    properties (SetAccess = {?modelTrainers.Base, ?Parameterized})
        performanceMeasure;
        maxDataSize;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function setFeatureMask(obj, newmask)
            assert(isvector(newmask));
            if(size(newmask,2)~=1), newmask = newmask'; end;                
            obj.featureMask = newmask;
        end
        
        function mask = getFeatureMask(obj)
            mask = obj.featureMask;
        end
        
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
        
        function performance = getPerformance( obj )
            verboseFprintf( obj, 'Applying model to test set...\n' );
            model = obj.getModel();
            performance = models.Base.getPerformance( ...
                model, obj.testSet, obj.positiveClass, obj.performanceMeasure );
        end
        %% ----------------------------------------------------------------

        function run( obj )
            [x,y] = obj.getPermutedTrainingData();
            if any( any( isnan( x ) ) ) || any( any( isinf( x ) ) ) 
                warning( 'There are NaNs or INFs in the data!' );
            end
            if numel( y ) > obj.maxDataSize
                x(obj.maxDataSize+1:end,:) = [];
                y(obj.maxDataSize+1:end) = [];
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
            if ~isempty(obj.featureMask)
                p_feat = size(x,2);
                p_mask = size(obj.featureMask,1);
                mask = obj.featureMask(1:min(p_feat,p_mask));
                x = x(:,mask);
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
    
end

