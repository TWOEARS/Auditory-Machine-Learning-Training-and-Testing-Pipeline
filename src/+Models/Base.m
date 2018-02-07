classdef (Abstract) Base < matlab.mixin.Copyable
    
    %% --------------------------------------------------------------------
    properties (SetAccess = {?ModelTrainers.Base})
        featureMask = [];
    end
    
    %% --------------------------------------------------------------------
    methods

        function [y,score] = applyModel( obj, x )
            if ~isempty( obj.featureMask )
                p_feat = size( x, 2 );
                p_mask = size( obj.featureMask, 1 );
                fmask = obj.featureMask( 1 : min( p_feat, p_mask ) );
                x = x(:,fmask);
            end
            verboseFprintf( obj, 'Testing, \tsize(x) = %dx%d\n', size(x,1), size(x,2) );
            [y,score] = obj.applyModelMasked( x );
        end
        %% -------------------------------------------------------------------------------
        
        function v = verbose( ~, newV )
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

    end

    %% --------------------------------------------------------------------
    methods (Abstract, Access = protected)
        [y,score] = applyModelMasked( obj, x )
    end

    %% --------------------------------------------------------------------
    methods (Static)
        
        function perf = getPerformance( model, testSet, perfMeasure, ...
                                        maxDataSize, dataSelector, importanceWeighter, ...
                                        getDatapointInfo )
            if isempty( testSet )
                warning( 'There is no testset to test on.' ); 
                perf = 0;
                return;
            end
            if nargin < 4  || isempty( maxDataSize )
                maxDataSize = inf; 
            end
            [x,yTrue,iw,vo,~,sampleIds] = ModelTrainers.Base.getSelectedData( ...
                          testSet, maxDataSize, dataSelector, importanceWeighter, true );
            if nargin < 7  || isempty( getDatapointInfo )
                getDatapointInfo = false; 
            end
            verboseFprintf( model, vo );
            if getDatapointInfo
                dpi.fileIdxs = testSet(:,'pointwiseFileIdxs');
                dpi.fileIdxs = dpi.fileIdxs(sampleIds);
                ufidxs = unique( dpi.fileIdxs );
                dpi.blockAnnotsCacheFiles(ufidxs) = testSet(ufidxs,'blockAnnotsCacheFile');
                dpi.fileNames(ufidxs) = testSet(ufidxs,'fileName');
                dpi.bIdxs = testSet(:,'bIdxs');
                dpi.bIdxs = dpi.bIdxs(sampleIds);
                dpi.bacfIdxs = testSet(:,'bacfIdxs');
                dpi.bacfIdxs = dpi.bacfIdxs(sampleIds);
            else
                dpi = struct.empty;
            end
            dpi(1).sampleIds = sampleIds;
            if isempty( x ), error( 'There is no data to test the model.' ); end
            yModel = model.applyModel( x );
            for ii = 1 : size( yModel, 2 )
                perf(ii) = perfMeasure( yTrue, yModel(:,ii), iw(:), dpi, testSet ); %#ok<AGROW>
            end
        end
        %% ----------------------------------------------------------------
    
    end
    
end

