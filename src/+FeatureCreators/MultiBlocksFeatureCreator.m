classdef MultiBlocksFeatureCreator < FeatureCreators.Base
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        featureCreators;
        blockLengths;
        block_back_offsets;
        arAssociations;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiBlocksFeatureCreator( featureCreators, blockLengths, block_back_offsets )
            obj = obj@FeatureCreators.Base();
            obj.featureCreators = featureCreators;
            obj.blockLengths = blockLengths;
            if nargin < 3 || isempty( block_back_offsets )
                block_back_offsets = zeros( size( blockLengths ) );
            elseif ~isequal( size( block_back_offsets ), size( blockLengths ) )
                error( 'size( block_back_offsets ) must equal size( blockLengths ).' );
            end
            obj.block_back_offsets = block_back_offsets;
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests = {};
            obj.arAssociations = cell( size( obj.featureCreators ) );
            for ii = 1 : numel( obj.featureCreators )
                ar_ii = obj.featureCreators{ii}.getAFErequests();
                obj.arAssociations{ii} = numel( afeRequests ) + 1 : numel( afeRequests ) + numel( ar_ii );
                afeRequests = [afeRequests ar_ii]; %#ok<AGROW>
            end
        end
        %% ----------------------------------------------------------------

        function x = constructVector( obj )
            x = {};
            for ii = 1 : numel( obj.blockLengths )
                obj.featureCreators{ii}.blockAnnotations = obj.blockAnnotations;
                obj.featureCreators{ii}.baIdx = obj.baIdx;
                ad = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
                for jj = 1 : numel( obj.arAssociations{ii} )
                    ad(jj) = obj.afeData(obj.arAssociations{ii}(jj));
                end
                curBAlen = obj.blockAnnotations(obj.baIdx).blockOffset ...
                    - obj.blockAnnotations(obj.baIdx).blockOnset;
                if  (curBAlen > (obj.blockLengths(ii) + obj.block_back_offsets(ii))) ...
                        || (obj.block_back_offsets(ii) > 0)
                    ad = BlockCreators.Base.cutAfeData( ad, obj.blockLengths(ii), obj.block_back_offsets(ii) );
                end
                obj.featureCreators{ii}.afeData = ad;
                x_ii = obj.featureCreators{ii}.constructVector();
                if ~obj.descriptionBuilt
                    x_ii{2} = cellfun( ...
                        @(c)([c {['bl' num2str( obj.blockLengths(ii) )], ['blo' num2str( obj.block_back_offsets(ii) )]}]), ...
                        x_ii{2}, 'UniformOutput', false );
                    obj.featureCreators{ii}.descriptionBuilt = true;
                end
                x = obj.concatFeats( x, x_ii );
            end
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            for ii = 1 : numel( obj.featureCreators )
                outputDeps.(['fc' num2str( ii )]) = obj.featureCreators{ii}.getInternOutputDependencies();
            end
            outputDeps.blockLengths = obj.blockLengths;
            outputDeps.block_back_offsets = obj.block_back_offsets;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

