classdef StandardBlockCreator < BlockCreators.Base
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = StandardBlockCreator( blockSize_s, shiftSize_s )
            obj = obj@BlockCreators.Base( blockSize_s, shiftSize_s );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.v = 1;
        end
        %% ------------------------------------------------------------------------------- 

        function [afeBlocks, blockAnnots] = blockify( obj, afeData, annotations )
            anyAFEsignal = afeData(1);
            if isa( anyAFEsignal, 'cell' ), anyAFEsignal = anyAFEsignal{1}; end;
            streamLen_s = double( length( anyAFEsignal.Data ) ) / anyAFEsignal.FsHz;
            backOffsets_s = ...
                       0.0 : obj.shiftSize_s : max( streamLen_s-obj.shiftSize_s+0.01, 0 );
            blockAnnots = repmat( annotations, numel( backOffsets_s ), 1 );
            blockOffsets = [streamLen_s - backOffsets_s]';
            blockOnsets = max( 0, blockOffsets - obj.blockSize_s );
            aFields = fieldnames( annotations );
            isSequenceAnnotation = cellfun( @(af)(...
                      isstruct( annotations.(af) ) && isfield( annotations.(af), 't' ) ...
                                                                             ), aFields );
            sequenceAfields = aFields(isSequenceAnnotation);
            afeBlocks = cell( numel( backOffsets_s ), 1 );
            for ii = 1 : numel( backOffsets_s )
                backOffset_s = backOffsets_s(ii);
                afeBlocks{ii} = obj.cutDataBlock( afeData, backOffset_s );
                blockOn = blockOnsets(ii);
                blockOff = blockOffsets(ii);
                for jj = 1 : numel( sequenceAfields )
                    seqAname = sequenceAfields{jj};
                    annot = annotations.(seqAname);
                    if ~isstruct( annot.t ) % time series
                        if size( annot.t ) == size( annot.(seqAname) )
                            isTinBlock = arrayfun( @(at)(...
                                                       at >= blockOn && at <= blockOff ...
                                                                             ), annot.t );
                            blockAnnots(jj).(seqAname).(seqAname)(~isTinBlock) = [];
                            blockAnnots(jj).(seqAname).t(~isTinBlock) = [];
                        else
                            error( 'unexpected annotations sequence structure' );
                        end
                    elseif all( isfield( annot.t, {'onset','offset'} ) ) % event series
                        if size( annot.t.onset ) == size( annot.t.offset ) && ...
                              size( annot.t.onset ) == size( annot.(sequenceAfields{jj}) )
                            isEventInBlock = arrayfun( @(eon,eoff)(...
                                               (eon >= blockOn && eon <= blockOff) || ...
                                              (eoff >= blockOn && eoff <= blockOff) || ...
                                               (eon <= blockOn && eoff >= blockOff)...
                                                       ), annot.t.onset, annot.t.offset );
                            blockAnnots(jj).(seqAname).(seqAname)(~isEventInBlock) = [];
                            blockAnnots(jj).(seqAname).t(~isEventInBlock) = [];
                            
                        else
                            error( 'unexpected annotations sequence structure' );
                        end
                    else
                        error( 'unexpected annotations sequence structure' );
                    end
                end
            end
            afeBlocks = flipud( afeBlocks );
            blockAnnots = flipud( blockAnnots );
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

