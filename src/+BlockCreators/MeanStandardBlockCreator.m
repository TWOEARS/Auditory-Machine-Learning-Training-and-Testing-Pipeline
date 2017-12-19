classdef MeanStandardBlockCreator < BlockCreators.StandardBlockCreator
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = MeanStandardBlockCreator( blockSize_s, shiftSize_s, varargin )
            obj = obj@BlockCreators.StandardBlockCreator( blockSize_s, shiftSize_s );
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.sbc = getBlockCreatorInternOutputDependencies@...
                                                BlockCreators.StandardBlockCreator( obj );
            outputDeps.v = 2;
        end
        %% ------------------------------------------------------------------------------- 

        function [blockAnnots,afeBlocks] = blockify( obj, afeData, annotations )
            if nargout > 1
                [blockAnnots,afeBlocks] = blockify@BlockCreators.StandardBlockCreator( ...
                                                              obj, afeData, annotations );
            else
                blockAnnots = blockify@BlockCreators.StandardBlockCreator( ...
                                                              obj, afeData, annotations );
            end
            aFields = fieldnames( blockAnnots );
            isSequenceAnnotation = cellfun( @(af)(...
                                            isstruct( blockAnnots(1).(af) ) && ...
                                            isfield( blockAnnots(1).(af), 't' ) && ...
                                            ~isstruct( blockAnnots(1).(af).t ) ...
                                                                             ), aFields );
            sequenceAfields = aFields(isSequenceAnnotation);
            for ii = 1 : numel( blockAnnots )
                for jj = 1 : numel( sequenceAfields )
                    seqAname = sequenceAfields{jj};
                    annot = blockAnnots(ii).(seqAname);
                    annotSeq = annot.(seqAname);
                    if length( annot.t ) == size( annotSeq, 1 )
                        if iscell( annotSeq )
                            as_szs = cellfun( @(c)( size( c, 2 ) ), annotSeq(1,:) );
                            blockAnnots(ii).(seqAname) = ...
                                   mat2cell( mean( cell2mat( annotSeq ), 1 ), 1, as_szs );
                        else
                            blockAnnots(ii).(seqAname) = mean( annotSeq, 1 );
                        end
                    else
                        error( 'unexpected annotations sequence structure' );
                    end
                end
                if ii == 1
                    [blockAnnots(:).nSrcs_sceneConfig] = deal([]);
                    [blockAnnots(:).nSrcs_active] = deal([]);
                    [blockAnnots(:).srcSNR2] = deal([]);
                end
                blockAnnots(ii) = obj.extendMeanAnnotations( blockAnnots(ii) );
            end
        end
        %% -------------------------------------------------------------------------------
        
        % TODO: this is the wrong place for the annotation computation; it
        % should be done in SceneEarSignalProc -- and is now here, for the
        % moment, to avoid recomputation with SceneEarSignalProc.
        
        function avgdBlockAnnots = extendMeanAnnotations( obj, avgdBlockAnnots )
            srcsEnergy = cellfun( @(se)(any(se > -40)), avgdBlockAnnots.srcEnergy );
            isAmbientSource = isnan( avgdBlockAnnots.srcAzms );
            srcsEnergy(isAmbientSource) = [];
            avgdBlockAnnots.nSrcs_sceneConfig = single( numel( avgdBlockAnnots.srcEnergy ) );
            avgdBlockAnnots.nSrcs_active = single( sum( srcsEnergy ) );
            avgdBlockAnnots.srcSNR = num2cell( 10 * log10( cell2mat( avgdBlockAnnots.srcSNR ) ) );
            avgdBlockAnnots.srcSNR2 = num2cell( 10 * log10( ...
                cell2mat( avgdBlockAnnots.nrj ) ./ cell2mat( avgdBlockAnnots.nrjOthers ) ) );
            avgdBlockAnnots.nrj = num2cell( 10 * log10( cell2mat( avgdBlockAnnots.nrj ) ) );
            avgdBlockAnnots.nrjOthers = num2cell( 10 * log10( cell2mat( avgdBlockAnnots.nrjOthers ) ) );
        end
        %% ------------------------------------------------------------------------------- 
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

