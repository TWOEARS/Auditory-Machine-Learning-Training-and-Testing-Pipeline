classdef (Abstract) Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        performance;
        datapointInfo;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = Base( yTrue, yPred, datapointInfo )
            if nargin < 2
                error( ['Subclass of PerformanceMeasures.Base must call superconstructor ',...
                        'and pass yTrue and yPred.'] );
            end
            if nargin < 3
                dpiarg = {};
            else
                dpiarg = {datapointInfo};
            end
            [obj, obj.performance, obj.datapointInfo] = ...
                obj.calcPerformance( yTrue, yPred, dpiarg{:} );
        end
        % -----------------------------------------------------------------
    
        function b = lt( obj, otherPm )
            b = ~( obj == otherPm ) && ~( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function po = strapOffDpi( obj )
            po = obj;
            po.datapointInfo = [];
        end
        % -----------------------------------------------------------------
    
        function b = le( obj, otherPm )
            b = ~( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = ge( obj, otherPm )
            b = ( obj == otherPm ) || ( obj > otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = ne( obj, otherPm )
            b = ~( obj == otherPm );
        end
        % -----------------------------------------------------------------
    
        function b = eq( obj1, obj2 )
            if isa( obj1, 'numeric' )
                b = obj1 == double( obj2 );
            elseif isa( obj2, 'numeric' )
                b = obj2 == double( obj1 );
            else
                b = obj1.eqPm( obj2 );
            end
        end
        % -----------------------------------------------------------------
    
        function b = gt( obj1, obj2 )
            if isa( obj1, 'numeric' )
                b = obj1 > double( obj2 );
            elseif isa( obj2, 'numeric' )
                b = double( obj1 ) > obj2;
            else
                b = obj1.gtPm( obj2 );
            end
        end
        % -----------------------------------------------------------------
        
        function disp( obj )
            disp( obj.char() );
        end
        % -----------------------------------------------------------------

        function [blockAnnotations, yp, yt] = getBacfDpi( obj, bacfIdx, bacfSubidx )
            allDpi = obj.datapointInfo;
            currentFileDpiIdxs = find( allDpi.fileIdxs == bacfIdx );
            currentFileBacfSubIdxs = allDpi.bacfIdxs(currentFileDpiIdxs);
            currentBacfDpiIdxs = currentFileDpiIdxs(currentFileBacfSubIdxs == bacfSubidx);
            currentBacfUsedIdxs = allDpi.bIdxs(currentBacfDpiIdxs);
            bacfile = load( allDpi.blockAnnotsCacheFiles{bacfIdx}{bacfSubidx}, 'blockAnnotations');
            blockAnnotations = bacfile.blockAnnotations(currentBacfUsedIdxs);
            yp = allDpi.yPred(currentBacfDpiIdxs);
            yt = allDpi.yTrue(currentBacfDpiIdxs);
        end
        % -----------------------------------------------------------------

    end

    %% --------------------------------------------------------------------
    methods (Abstract)
        [obj, performance, dpi] = calcPerformance( obj, yTrue, yPred, dpiarg )
        b = eqPm( obj, otherPm )
        b = gtPm( obj, otherPm )
        s = char( obj )
        d = double( obj )
    end
    
end

