classdef DnnLocKsWrapper < DataProcs.BlackboardKsWrapper
    % Wrapping the SegmentationKS
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = public)
        dnnHash;
        nfHash;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = DnnLocKsWrapper()
            dnnLocKs = DnnLocationKS();
            obj = obj@DataProcs.BlackboardKsWrapper( dnnLocKs );
            obj.dnnHash = calcDataHash( dnnLocKs.DNNs );
            obj.nfHash = calcDataHash( dnnLocKs.normFactors );
        end
        %% -------------------------------------------------------------------------------
        
        function procBlock = preproc( obj, blockAnnotations )
            procBlock = true;
            warning( 'off', 'BBS:badBlockTimeRequest' );
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj, afeData, blockAnnotations )
            locHypos = obj.bbs.blackboard.getLastData( 'sourcesAzimuthsDistributionHypotheses' );
            assert( numel( locHypos.data ) == 1 );
            obj.out.afeBlocks{end+1,1} = DnnLocKsWrapper.addLocData( afeData, locHypos.data );
            if isempty(obj.out.blockAnnotations)
                obj.out.blockAnnotations = blockAnnotations;
            else
                obj.out.blockAnnotations(end+1,1) = blockAnnotations;
            end
            warning( 'on', 'BBS:badBlockTimeRequest' );
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getKsInternOutputDependencies( obj )
            outputDeps.v = 1;
            outputDeps.bs = obj.ks.blockSize;
            outputDeps.nc = obj.ks.nChannels;
            outputDeps.fr = obj.ks.freqRange;
            outputDeps.dn = obj.dnnHash;
            outputDeps.nf = obj.nfHash;
            outputDeps.an = obj.ks.angles;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
        function afeData = addLocData( afeData, locData )
            locFakeAFEsignal = struct();
            locFakeAFEsignal.Data = locData.sourcesDistribution;
            locFakeAFEsignal.Name = 'DnnLocationDistribution';
            locFakeAFEsignal.azms = locData.azimuths;
            afeData(afeData.Count+1) = locFakeAFEsignal;
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

