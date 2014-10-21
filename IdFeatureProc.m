classdef IdFeatureProc < IdProcInterface

    %%---------------------------------------------------------------------
    properties (SetAccess = private, Transient)
        buildWp1FileName;
        buildWp2FileName;
    end
    properties (SetAccess = private)
        blockSize_s;
        shiftSize_s;
        minBlockToEventRatio;
        featureProc;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdFeatureProc( featureProc )
            if ~isa( featureProc, 'FeatureProcInterface' )
                error( 'FeatureProcessor must be of type FeatureProcInterface.' );
            end
            obj = obj@IdProcInterface();
            obj.blockSize_s = 0.5;
            obj.shiftSize_s = 0.25;
            obj.minBlockToEventRatio = 0.5;
            obj.featureProc = featureProc;
        end

        %%-----------------------------------------------------------------
            
        function setWp1FileNameBuilder( obj, wp1FileNameBuilder )
            obj.buildWp1FileName = wp1FileNameBuilder;
        end
            
        function setWp2FileNameBuilder( obj, wp2FileNameBuilder )
            obj.buildWp2FileName = wp2FileNameBuilder;
        end
        
        %%-----------------------------------------------------------------

        function wp2Requests = getWp2Requests( obj )
            wp2Requests = obj.featureProc.getWp2Requests();
        end
        
        %%-----------------------------------------------------------------

        function run( obj )
            fprintf( 'feature creation' );
            for trainFile = obj.data(:)'
                featuresFileName = obj.buildProcFileName( trainFile.wavFileName );
                fprintf( '\n.%s', featuresFileName );
                if exist( featuresFileName, 'file' )
                    featuresMat = load( featuresFileName );
                    trainFile.x = featuresMat.x;
                    trainFile.y = featuresMat.y;
                    continue;
                end
                wp1mat = load( obj.buildWp1FileName( trainFile.wavFileName ) );
                wp2mat = load( obj.buildWp2FileName( trainFile.wavFileName ) );
                [wp2blocks, y] = obj.blockifyAndLabel( wp2mat.wp2data, wp1mat.earsOnOffs );
                for wp2block = wp2blocks
                    x = obj.featureProc.makeDataPoint( wp2block{1} );
                    trainFile.x(end+1,:) = x;
                end
                trainFile.y = y;
                x = trainFile.x;
                save( featuresFileName, 'x', 'y' );
            end
            fprintf( ';\n' );
        end
        
        %%-----------------------------------------------------------------
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    
        function [wp2blocks, y] = blockifyAndLabel( obj, wp2data, earsOnOffs )
            wp2blocks = {};
            y = [];
            wp2dataNames = wp2data.keys;
            anyWp2signal = wp2data(wp2dataNames{1});
            if isa( anyWp2signal, 'cell' ), anyWp2signal = anyWp2signal{1}; end;
            sigLen = double( length( anyWp2signal.Data ) ) / anyWp2signal.FsHz;
            for backOffset = 0.0:obj.shiftSize_s:sigLen
                wp2block = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
                for wp2dataKey = wp2dataNames
                    wp2signal = wp2data(wp2dataKey{1});
                    if isa( wp2signal, 'cell' )
                        wp2signalExtract{1} = wp2signal{1}.cutSignalCopy( obj.blockSize_s, backOffset );
                        wp2signalExtract{1}.reduceBufferToArray();
                        wp2signalExtract{2} = wp2signal{2}.cutSignalCopy( obj.blockSize_s, backOffset );
                        wp2signalExtract{2}.reduceBufferToArray();
                    else
                        wp2signalExtract = wp2signal.cutSignalCopy( obj.blockSize_s, backOffset );
                    end
                    wp2block(wp2dataKey{1}) = wp2signalExtract;
                    fprintf( '.' );
                end
                wp2blocks{end+1} = wp2block;
                blockOffset = sigLen - backOffset;
                blockOnset = blockOffset - obj.blockSize_s;
                y(end+1) = 0;
                for jj = 1 : size( earsOnOffs, 1 )
                    eventOnset = earsOnOffs(jj,1);
                    eventOffset = earsOnOffs(jj,2);
                    eventLength = eventOffset - eventOnset;
                    maxBlockEventLen = min( obj.blockSize_s, eventLength );
                    eventBlockOverlapLen = min( blockOffset, eventOffset ) - max( blockOnset, eventOnset );
                    relEventBlockOverlap = eventBlockOverlapLen / maxBlockEventLen;
                    blockIsSoundEvent = relEventBlockOverlap > obj.minBlockToEventRatio;
                    y(end) = y(end) || blockIsSoundEvent;
                    if y(end) == 1, break, end;
                end
            end
            wp2blocks = fliplr( wp2blocks );
            y = fliplr( y );
            y = y';
            %scaling to [-1..1]
            y = (y * 2) - 1;
        end
        
    end
    
    %%---------------------------------------------------------------------
    
end

