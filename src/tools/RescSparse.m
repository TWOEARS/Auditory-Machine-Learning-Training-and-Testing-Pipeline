classdef RescSparse
    % class for results count sparse matrices
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = public)
        dataConvert;
        dataIdxsConvert;
        data;
        dataIdxs;
        dataInitialize;
        dataAdd;
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods
        
        function obj = RescSparse( datatype, dataidxstype, dataInitialize, dataAdd )
            if nargin < 1 || isempty( datatype )
                datatype = 'double';
            end
            switch datatype
                case 'double'
                    obj.dataConvert = @double;
                case 'single'
                    obj.dataConvert = @single;
                case 'int64'
                    obj.dataConvert = @int64;
                case 'int32'
                    obj.dataConvert = @int32;
                case 'int16'
                    obj.dataConvert = @int16;
                case 'int8'
                    obj.dataConvert = @int8;
                case 'uint64'
                    obj.dataConvert = @uint64;
                case 'uint32'
                    obj.dataConvert = @uint32;
                case 'uint16'
                    obj.dataConvert = @uint16;
                case 'uint8'
                    obj.dataConvert = @uint8;
                case 'logical'
                    obj.dataConvert = @logical;
                otherwise
                    obj.dataConvert = @double;
            end
            if nargin < 2 || isempty( dataidxstype )
                dataidxstype = 'double';
            end
            switch dataidxstype
                case 'double'
                    obj.dataIdxsConvert = @double;
                case 'single'
                    obj.dataIdxsConvert = @single;
                case 'int64'
                    obj.dataIdxsConvert = @int64;
                case 'int32'
                    obj.dataIdxsConvert = @int32;
                case 'int16'
                    obj.dataIdxsConvert = @int16;
                case 'int8'
                    obj.dataIdxsConvert = @int8;
                case 'uint64'
                    obj.dataIdxsConvert = @uint64;
                case 'uint32'
                    obj.dataIdxsConvert = @uint32;
                case 'uint16'
                    obj.dataIdxsConvert = @uint16;
                case 'uint8'
                    obj.dataIdxsConvert = @uint8;
                case 'logical'
                    obj.dataIdxsConvert = @logical;
                otherwise
                    obj.dataIdxsConvert = @double;
            end
            if nargin < 3 || isempty( dataInitialize )
                dataInitialize = obj.dataConvert( 0 );
            end
            obj.dataInitialize = dataInitialize;
            if nargin < 4 || isempty( dataAdd )
                dataAdd = @(a,b)(a+b);
            end
            obj.dataAdd = dataAdd;
            obj.data = obj.dataConvert( zeros( 0 ) );
            obj.dataIdxs = obj.dataIdxsConvert( zeros( 0 ) );
        end
        %% -------------------------------------------------------------------------------
        
        function value = get( obj, idxs )
            value = 0;
            if size( idxs, 2 ) < size( obj.dataIdxs, 2 )
                error( 'AMLTTP:usage:unexpected', 'idxs dimensions too small.' );
            end
            if size( idxs, 2 ) > size( obj.dataIdxs, 2 )
                error( 'AMLTTP:usage:unexpected', 'idxs dimensions too big.' );
            end
            rowIdxEq = obj.rowSearch( idxs );
            if rowIdxEq ~= 0
                value = obj.data(rowIdxEq,:);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function [data,dataIdxs] = getRowIndexed( obj, rowIdxs )
            if max( rowIdxs ) > size( obj.dataIdxs, 1 )
                error( 'AMLTTP:usage:unexpected', 'max rowIdxs too big.' );
            end
            data = obj.data(rowIdxs,:);
            if nargout > 1
                dataIdxs = obj.dataIdxs(rowIdxs,:);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function rowIdxs = getRowIdxs( obj, idxsMask )
            if size( idxsMask, 2 ) ~= size( obj.dataIdxs, 2 )
                error( 'AMLTTP:usage:unexpected', 'idxsMask dimensions wrong.' );
            end
            dataIdxsMask = true( size( obj.dataIdxs ) );
            for ii = 1 : size( obj.dataIdxs, 2 )
                if ischar( idxsMask{ii} ) && idxsMask{ii} == ':', continue; end
                if ii == 1
                    dataIdxsMask(:,ii) = idxsMask{ii}( obj.dataIdxs(:,ii) );
                else
                    dataIdxsMask(dataIdxsMask(:,ii-1),ii) = idxsMask{ii}( obj.dataIdxs(dataIdxsMask(:,ii-1),ii) );
                end
            end
            rowIdxsMask = all( dataIdxsMask, 2 );
            rowIdxs = find( rowIdxsMask );
        end
        %% -------------------------------------------------------------------------------
        
        function obj = deleteData( obj, rowIdxs )
            if max( rowIdxs ) > size( obj.dataIdxs, 1 )
                error( 'AMLTTP:usage:unexpected', 'max rowIdxs too big.' );
            end
            obj.data(rowIdxs,:) = [];
            obj.dataIdxs(rowIdxs,:) = [];
        end
        %% -------------------------------------------------------------------------------
        
        function obj = addData( obj, idxs, data )
            idxs = obj.dataIdxsConvert( idxs );
            data = obj.dataConvert( data );
            if size( idxs, 2 ) < size( obj.dataIdxs, 2 )
                error( 'AMLTTP:usage:unexpected', 'idxs dimensions too small.' );
            end
            if size( idxs, 2 ) > size( obj.dataIdxs, 2 )
                if isempty( obj.dataIdxs )
                    obj.dataIdxs = obj.dataIdxsConvert( zeros( 0, size( idxs, 2 ) ) );
                else
                    obj.dataIdxs(:,size( obj.dataIdxs, 2 )+1:size( idxs, 2 )) = obj.dataIdxsConvert( 1 );
                end
            end
            rowIdxEq = zeros( size( idxs, 1 ), 1 );
            rowIdxGt = zeros( size( idxs, 1 ), 1 );
            for ii = 1 : size( idxs, 1 )
                [rowIdxEq(ii),~,rowIdxGt(ii)] = obj.rowSearch( idxs(ii,:) );
                if rowIdxEq(ii) ~= 0
                    obj.data(rowIdxEq(ii),:) = obj.dataAdd( obj.data(rowIdxEq(ii),:), data(ii,:) );
                end
            end
            rowIdxGt(rowIdxEq ~= 0) = [];
            idxs(rowIdxEq ~= 0,:) = [];
            data(rowIdxEq ~= 0,:) = [];
            [rigtidxs,order] = sortrows( [rowIdxGt,double( idxs )] );
            incidxs = sort( [rigtidxs(:,1); (1:size( obj.dataIdxs, 1 ))'] );
            obj.dataIdxs(end+1,:) = obj.dataIdxsConvert( 0 );
            obj.data(end+1,:) = obj.dataConvert( 0 );
            obj.dataIdxs = obj.dataIdxs(incidxs,:);
            obj.data = obj.data(incidxs,:);
            rigtidxs(:,1) = rigtidxs(:,1) + (0:size( rigtidxs, 1 )-1)';
            obj.dataIdxs(rigtidxs(:,1),:) = rigtidxs(:,2:end);
            obj.data(rigtidxs(:,1),:) = data(order,:);
        end
        %% -------------------------------------------------------------------------------

        function [rowIdxEq,rowIdxLt,rowIdxGt] = rowSearch( obj, idxs, preRowIdxGt )
%             if numel( idxs ) ~= size( obj.dataIdxs, 2 )
%                 error( 'AMLTTP:implementation:unexpected', 'This should not have happened.' );
%             end
            rowIdxEq = 0; 
            rowIdxLt = 0;
            if nargin < 3 || isempty( preRowIdxGt )
                preRowIdxGt = size( obj.dataIdxs, 1 );
            end
            rowIdxGt = preRowIdxGt + 1;
            ni = size( idxs, 2 );
            while rowIdxGt - rowIdxLt > 1
                mRowIdx = floor( 0.5*rowIdxLt + 0.5*rowIdxGt );
                idxAreEq = 1; idxAisltB = 0; idxAisgtB = 0;
                for ii = 1 : ni
                    if idxs(ii) < obj.dataIdxs(mRowIdx,ii)
                        idxAisltB = 1;
                        idxAreEq = 0;
                        break;
                    elseif idxs(ii) > obj.dataIdxs(mRowIdx,ii)
                        idxAisgtB = 1;
                        idxAreEq = 0;
                        break;
                    end
                end
                if idxAreEq
                    rowIdxEq = mRowIdx;
                    rowIdxLt = mRowIdx - 1;
                    rowIdxGt = mRowIdx + 1;
                    break;
                elseif idxAisltB
                    rowIdxGt = mRowIdx;
                elseif idxAisgtB
                    rowIdxLt = mRowIdx;
                end
            end
        end
        %% -------------------------------------------------------------------------------

    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        function [idxAreEq,idxAisltB,idxAisgtB] = idxsCmp( idxsA, idxsB )
            idxAreEq = 0; idxAisltB = 0; idxAisgtB = 0;
%             if numel( idxsA ) ~= numel( idxsB )
%                 error( 'AMLTTP:implementation:unexpected', 'This should not have happened.' );
%             end
            for ii = 1 : size( idxsA, 2 )
                if idxsA(ii) < idxsB(ii)
                    idxAisltB = 1;
                    return;
                elseif idxsA(ii) > idxsB(ii)
                    idxAisgtB = 1;
                    return;
                end
            end
            idxAreEq = 1;
        end
        %% -------------------------------------------------------------------------------

end
    
end
