classdef MultiEventTypeBlockInterpreteTimeSeriesLabeler < LabelCreators.TimeSeriesLabelCreator
    % class for multi-class labeling blocks by event
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        types;
        negOut;
        srcPrioMethod;
        segIdTargetSrcFilter = [];
        srcTypeFilterOut;
        fileFilterOut = {};
        blockLength;
        minBlockToEventRatio;
        maxNegBlockToEventRatio;
    end
    
    %% -----------------------------------------------------------------------------------
    properties (Access = public)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MultiEventTypeBlockInterpreteTimeSeriesLabeler( varargin )
            ip = inputParser;
            ip.addOptional( 'blockLength', 50 ); % frames
            ip.addOptional( 'minBlockToEventRatio', 0.75 );
            ip.addOptional( 'maxNegBlockToEventRatio', 0 );
            ip.addOptional( 'removeUnclearBlocks', 'sequence-wise' );
            ip.addOptional( 'types', {{'Type1'},{'Type2'}} );
            ip.addOptional( 'negOut', 'rest' ); % rest, none
            ip.addOptional( 'srcPrioMethod', 'time' ); % energy, time, order
%             ip.addOptional( 'segIdTargetSrcFilter', [] ); % e.g. [1,1;3,2]: throw away time-aggregate blocks with type 1 on other than src 1 and type 2 on other than src 3
            ip.addOptional( 'srcTypeFilterOut', [] ); % e.g. [2,1;3,2]: throw away type 1 blocks from src 2 and type 2 blocks from src 3
%             ip.addOptional( 'fileFilterOut', {} ); % blocks containing these files get filtered out
            ip.parse( varargin{:} );
            obj = obj@LabelCreators.TimeSeriesLabelCreator( 'removeUnclearBlocks', ...
                                                         ip.Results.removeUnclearBlocks );
            obj.types = ip.Results.types;
            obj.minBlockToEventRatio = ip.Results.minBlockToEventRatio;
            obj.maxNegBlockToEventRatio = ip.Results.maxNegBlockToEventRatio;
            obj.blockLength = ip.Results.blockLength;
            obj.negOut = ip.Results.negOut;
            obj.srcPrioMethod = ip.Results.srcPrioMethod;
%             obj.segIdTargetSrcFilter = ip.Results.segIdTargetSrcFilter;
            obj.srcTypeFilterOut = ip.Results.srcTypeFilterOut;
%             obj.fileFilterOut = sort( ip.Results.fileFilterOut );
            obj.procName = [obj.procName '(' strcat( obj.types{1}{:} ) ')'];
        end
        %% -------------------------------------------------------------------------------
        
        function [y, ysi] = label( obj, blockAnnotations )
            [activeTypes, srcIdxs] = obj.getActiveTypes( blockAnnotations );
            y = zeros( size( activeTypes, 1 ), 1 );
            ysi = cell( size( activeTypes, 1 ), 1 );
            if any( activeTypes(:) )
                switch obj.srcPrioMethod
                    case 'energy'
                        error( 'AMLTTP:notImplemented', 'energy PrioMethod for time-series not implemented yet' );
                    case 'order'
                        [~,y] = max( [zeros( size( activeTypes, 1 ), 1 ), ...
                                      activeTypes > obj.minBlockToEventRatio], [], 2 );
                        y = y - 1;
                    case 'time'
                        [maxActiveBI,y] = max( activeTypes, [], 2 );
                        y(maxActiveBI < obj.minBlockToEventRatio) = 0;
                    otherwise
                        error( 'AMLTTP:unknownOptionValue', ['%s: unknown option value.'...
                                     'Use ''energy'' or ''order''.'], obj.srcPrioMethod );
                end
                ysi_ = y;
                ysi_(ysi_==0) = 1;
                ysi = srcIdxs(sub2ind( size( srcIdxs ), 1:size( srcIdxs, 1 ), ysi_' ));
            end
            if strcmp( obj.negOut, 'rest' )
                atBI = max( activeTypes(y == 0,:), [], 2 );
                y(y == 0) = -1 * (atBI <= obj.maxNegBlockToEventRatio);
            end
%             if ~isempty( obj.segIdTargetSrcFilter )
%                 for ii = 1 : size( obj.segIdTargetSrcFilter, 1 )
%                     srcf = obj.segIdTargetSrcFilter(ii,1);
%                     typef = obj.segIdTargetSrcFilter(ii,2);
%                     srcfAzm = obj.lastConfig{obj.sceneId,obj.foldId}.preceding.preceding.preceding.preceding.preceding.sceneCfg.sources(srcf).azimuth;
%                     if isa( srcfAzm, 'SceneConfig.ValGen' )
%                         srcfAzm = srcfAzm.val;
%                     end
%                     if activeTypes(typef) && any( abs( blockAnnotations.srcAzms(srcIdxs{typef}) - srcfAzm ) >= 0.1 )
%                         y = NaN;
%                         return;
%                     end
%                 end
%             end
            if any( activeTypes(:) )
                for ii = 1 : size( obj.srcTypeFilterOut, 1 )
                    srcfo = obj.srcTypeFilterOut(ii,1);
                    if srcfo > max( [blockAnnotations.srcType.srcType{:,2}] )
                        continue;
                    end
                    typefo = obj.srcTypeFilterOut(ii,2);
                    fo_lidxs = activeTypes(:,typefo) ...
                               & cellfun( @(si)(any( si == srcfo )), srcIdxs(:,typefo) );
                    y(fo_lidxs) = NaN;
                end
            end
%             for ii = 1 : numel( obj.fileFilterOut )
%                 if any( strcmpi( obj.fileFilterOut{ii}, blockAnnotations.srcFile.srcFile(:,1) ) )
%                     y = NaN;
%                     return;
%                 end
%             end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function outputDeps = getLabelInternOutputDependencies( obj )
            outputDeps.minBlockEventRatio = obj.minBlockToEventRatio;
            outputDeps.maxNegBlockToEventRatio = obj.maxNegBlockToEventRatio;
            outputDeps.types = obj.types;
            outputDeps.blockLength = obj.blockLength;
            outputDeps.negOut = obj.negOut;
            outputDeps.srcPrioMethod = obj.srcPrioMethod;
            outputDeps.srcTypeFilterOut = sortrows( obj.srcTypeFilterOut );
            outputDeps.segIdTargetSrcFilter = sortrows( obj.segIdTargetSrcFilter );
            outputDeps.fileFilterOut = obj.fileFilterOut;
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------
        
        function eit = eventIsType( obj, typeIdx, type )
            eit = any( strcmp( type, obj.types{typeIdx} ) );
        end
        %% -------------------------------------------------------------------------------
        
        function [activeTypesBI, srcIdxsBI] = getActiveTypes( obj, blockAnnotations )
            ts = blockAnnotations.globalSrcEnergy.t;
            activeTypes = zeros( numel( ts ), numel( obj.types ) );
            srcIdxs = cell( numel( ts ), numel( obj.types ) );
            eventOnsets = blockAnnotations.srcType.t.onset;
            eventOffsets = blockAnnotations.srcType.t.offset;
            for tt = 1 : numel( obj.types )
                eventsAreType = cellfun( @(ba)(obj.eventIsType( tt, ba )), ...
                                                  blockAnnotations.srcType.srcType(:,1) );
                srcIdxs_tt = [blockAnnotations.srcType.srcType{eventsAreType,2}];
                eventOnOffs_tt = [eventOnsets(eventsAreType)',eventOffsets(eventsAreType)'];
                eventOnOffs_tt = eventOnOffs_tt - ts(1) + 1;
                if ~isempty( eventOnOffs_tt )
                    for ii = 1:2
                        eventOnOffs_tt(:,ii) = max( ...
                                                [zeros( size(eventOnOffs_tt, 1), 1 ), ...
                                                 eventOnOffs_tt(:,ii)], [], 2 );
                        eventOnOffs_tt(:,ii) = min( ...
                                   [repmat( numel( ts ), size(eventOnOffs_tt, 1), 1 ), ...
                                    eventOnOffs_tt(:,ii)], [], 2 );
                    end
                else
                    eventOnOffs_tt = [];
                end
                for jj = 1 : size( eventOnOffs_tt, 1 )
                    event_jj_idxs = eventOnOffs_tt(jj,1) : eventOnOffs_tt(jj,2);
                    activeTypes(event_jj_idxs,tt) = 1;
                    srcIdxs(event_jj_idxs,tt) = cellfun( @(a,b)([a,b]), ...
                                srcIdxs(event_jj_idxs,tt), ...
                                repmat( {srcIdxs_tt(jj)}, numel( event_jj_idxs ), 1 ), ...
                                                                 'UniformOutput', false );
                end
            end
            eventLengths = zeros( size( activeTypes ) );
            atChange = activeTypes - ...
                     cat( 1, zeros( 1, size( activeTypes, 2 ) ), activeTypes(1:end-1,:) );
            atChange(atChange<0) = 0;
            atChangeIdxs = atChange .* repmat( (1:size( atChange, 1 ))', 1, size( atChange, 2 ) );
            for ii = 2 : size( atChangeIdxs, 1 )
                atChangeIdxs(ii,:) = activeTypes(ii,:) .* atChangeIdxs(ii-1,:) + ...
                                     ~activeTypes(ii-1,:) .* atChangeIdxs(ii,:);
            end
            eventLengths(end,:) = activeTypes(end,:);
            for ii = size( activeTypes, 1 ) - 1 : -1 : 1
                eventLengths(ii,:) = activeTypes(ii,:) .* ...
                                               (eventLengths(ii+1,:) + activeTypes(ii,:));
            end
            activeFrameLengths = zeros( 1, size( activeTypes, 2 ) );
            blockEventLengths = zeros( 1, size( activeTypes, 2 ) );
            activeTypesBI = zeros( size( activeTypes ) );
            srcIdxsBI = cell( size( activeTypes ) );
            for ii = 1 : size( activeTypes, 1 )
                activeFrameLengths = activeFrameLengths + activeTypes(ii,:);
                if ii > obj.blockLength
                    activeFrameLengths = activeFrameLengths - activeTypes(ii-obj.blockLength,:);
                end
                for jj = 1 : size( activeTypes, 2 )
                    uaci = unique( atChangeIdxs(max(1,ii-obj.blockLength):ii,jj) );
                    uaci(uaci==0) = [];
                    blockEventLengths(jj) = ...
                                     min( obj.blockLength, sum( eventLengths(uaci,jj) ) );
                    srcIdxsBI{ii,jj} = unique( [srcIdxs{max(1,ii-obj.blockLength):ii,jj}] );
                end
                activeEventRatio = activeFrameLengths ./ ...
                              max( ones( size( blockEventLengths ) ), blockEventLengths );
                activeTypesBI(ii,:) = activeEventRatio;
            end
        end
        %% -------------------------------------------------------------------------------
               
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

