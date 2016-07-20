classdef (Abstract) Base < handle
    
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
                                        maxDataSize, balMaxData, getDatapointInfo )
            if isempty( testSet )
                warning( 'There is no testset to test on.' ); 
                perf = 0;
                return;
            end
            if nargin < 4, maxDataSize = inf; end
            if nargin < 5, balMaxData = false; end
            if nargin < 6, getDatapointInfo = 'noInfo'; end
            x = testSet(:,'x');
            yTrue = testSet(:,'y');
            delPosIdxs = [];
            delNegIdxs = [];
            if numel( yTrue ) > maxDataSize
                if balMaxData
                    nPos = min( int32( maxDataSize/2 ), sum( yTrue == +1 ) );
                    nNeg = maxDataSize - nPos;
                    delPosIdxs = find( yTrue == +1 );
                    delPosIdxs = delPosIdxs(randperm(numel(delPosIdxs)));
                    delPosIdxs(1:nPos) = [];
                    delNegIdxs = find( yTrue == -1 );
                    delNegIdxs = delNegIdxs(randperm(numel(delNegIdxs)));
                    delNegIdxs(1:nNeg) = [];
                else
                    delPosIdxs = maxDataSize + 1 : size( x, 1 );
                end
                x([delPosIdxs; delNegIdxs],:) = [];
                yTrue([delPosIdxs; delNegIdxs]) = [];
            end
            if strcmpi( getDatapointInfo, 'datapointInfo' )
                dpi.fileIdxs = testSet(:,'pointwiseFileIdxs');
                dpi.fileIdxs([delPosIdxs; delNegIdxs]) = [];
                ufidxs = unique( dpi.fileIdxs );
                dpi.blockAnnotsCacheFiles(ufidxs) = testSet(ufidxs,'blockAnnotsCacheFile');
                dpi.fileNames(ufidxs) = testSet(ufidxs,'fileName');
                dpi.bIdxs = testSet(:,'bIdxs');
                dpi.bIdxs([delPosIdxs; delNegIdxs]) = [];
                dpi.bacfIdxs = testSet(:,'bacfIdxs');
                dpi.bacfIdxs([delPosIdxs; delNegIdxs]) = [];
                dpiarg = {dpi};
            else
                dpiarg = {};
            end
            if isempty( x ), error( 'There is no data to test the model.' ); end
            yModel = model.applyModel( x );
            for ii = 1 : size( yModel, 2 )
                perf(ii) = perfMeasure( yTrue, yModel(:,ii), dpiarg{:} );
            end
        end
        %% ----------------------------------------------------------------
    
    end
    
end

