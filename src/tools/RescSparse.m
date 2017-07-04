classdef RescSparse
    % class for results count sparse matrices
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = public)
        dataConvert;
        dataIdxsConvert;
        data;
        dataIdxs;
        dataSize;
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
            obj.dataSize = 0;
        end
        %% -------------------------------------------------------------------------------
        
        function value = get( obj, varargin )
            value = 0;
            if numel( varargin ) > size( obj.dataIdxs, 2 )
                return;
            end
            if any( [varargin{:}] > obj.dataSize )
                return;
            end
            
        end
        %% -------------------------------------------------------------------------------
        
        function obj = addData( obj, idxs, data )
            idxs = obj.dataIdxsConvert( idxs );
            data = obj.dataConvert( data );
            if numel( idxs ) < size( obj.dataIdxs, 2 )
                error( 'AMLTTP:implementation:unexpected', 'This should not have happened.' );
            end
            if numel( idxs ) > size( obj.dataIdxs, 2 )
                if isempty( obj.dataIdxs )
                    obj.dataIdxs = obj.dataIdxsConvert( zeros( 0, numel( idxs ) ) );
                else
                    obj.dataIdxs(:,size( obj.dataIdxs, 2 )+1:numel( idxs )) = obj.dataIdxsConvert( 1 );
                end
            end
            [rowIdxEq,~,rowIdxGt] = obj.rowSearch( idxs );
            if rowIdxEq ~= 0
                obj.data(rowIdxEq,:) = obj.dataAdd( obj.data(rowIdxEq,:), data );
            else
                if rowIdxGt <= size( obj.dataIdxs, 1 )
                    obj.dataIdxs(rowIdxGt+1:end+1,:) = obj.dataIdxs(rowIdxGt:end,:);
                    obj.data(rowIdxGt+1:end+1,:) = obj.data(rowIdxGt:end,:);
                end
                obj.dataIdxs(rowIdxGt,:) = idxs;
                obj.data(rowIdxGt,:) = obj.dataAdd( obj.dataInitialize, data );
            end
        end
        %% -------------------------------------------------------------------------------
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = public)

        function [rowIdxEq,rowIdxLt,rowIdxGt] = rowSearch( obj, idxs )
            rowIdxEq = 0; 
            rowIdxLt = 0;
            rowIdxGt = size( obj.dataIdxs, 1 ) + 1;
            if numel( idxs ) ~= size( obj.dataIdxs, 2 )
                error( 'AMLTTP:implementation:unexpected', 'This should not have happened.' );
            end
            while rowIdxGt - rowIdxLt > 1
                mRowIdx = floor( 0.5*rowIdxLt + 0.5*rowIdxGt );
                mIdxs = obj.dataIdxs(mRowIdx,:);
                [idxAreEq,idxAisltB,idxAisgtB] = RescSparse.idxsCmp( idxs, mIdxs );
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
            if numel( idxsA ) ~= numel( idxsB )
                error( 'AMLTTP:implementation:unexpected', 'This should not have happened.' );
            end
            for ii = 1 : numel( idxsA )
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
