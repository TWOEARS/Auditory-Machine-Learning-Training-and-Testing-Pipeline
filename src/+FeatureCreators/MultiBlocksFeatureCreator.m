classdef MultiBlocksFeatureCreator < FeatureCreators.Base
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        featureCreators;
        blockLengths;
        arAssociations;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiBlocksFeatureCreator( featureCreators, blockLengths )
            obj = obj@FeatureCreators.Base();
            obj.featureCreators = featureCreators;
            obj.blockLengths = blockLengths;
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
                if obj.blockAnnotations(obj.baIdx).blockOffset ...
                        - obj.blockAnnotations(obj.baIdx).blockOnset > obj.blockLengths(ii)
                    ad = BlockCreators.Base.cutAfeData( ad, obj.blockLengths(ii), 0 );
                end
                obj.featureCreators{ii}.afeData = ad;
                x_ii = obj.featureCreators{ii}.constructVector();
                if ~obj.descriptionBuilt
                    x_ii{2} = cellfun( @(c)([c {['bl' num2str( obj.blockLengths(ii) )]}]), x_ii{2}, 'UniformOutput', false );
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

