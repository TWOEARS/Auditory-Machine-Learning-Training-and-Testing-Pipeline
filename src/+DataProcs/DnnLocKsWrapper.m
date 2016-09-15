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
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj, afeData, blockAnnotations )
            locHypos = obj.bbs.blackboard.getLastData( 'sourcesAzimuthsDistributionHypotheses' );
            assert( numel( locHypos.data ) == 1 );
            obj.out.afeBlocks{end+1,1} = obj.addLocData( afeData, locHypos.data );
            if isempty(obj.out.blockAnnotations)
                obj.out.blockAnnotations = blockAnnotations;
            else
                obj.out.blockAnnotations(end+1,1) = blockAnnotations;
            end
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
    methods (Access = protected)
        
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

