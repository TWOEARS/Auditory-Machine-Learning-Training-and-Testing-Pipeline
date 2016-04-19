classdef SegmentKsWrapper < DataProcs.BlackboardKsWrapper
    % Wrapping the SegmentationKS
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Abstract)
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = SegmentKsWrapper( afeDataIndexOffset, name, varargin )
            segmentKs = SegmentationKS( name, varargin{:} );
            obj = obj@DataProcs.BlackboardKsWrapper( segmentKs, afeDataIndexOffset );
        end
        %% -------------------------------------------------------------------------------
        
        function preproc( obj, blockAnnotations )
            prior = [];
            for ii = 1 : obj.ks.nSources
                azm = []; %TODO read azm from blockAnnotations
                prior(end+1) = deg2rad( azm );
                if prior(end) > pi, prior(end) = -deg2rad( azm ); end
            end
            obj.ks.setFixedPositions( prior );
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj )
            segHypos = obj.bbs.blackboard.getLastData( 'segmentationHypotheses' );
            segHypos = segHypos.data;
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getKsInternOutputDependencies( obj )
            outputDeps.v = 1;
            outputDeps.blockSize = obj.ks.blockSize;
            outputDeps.nSources = obj.ks.nSources;
            outputDeps.positions = obj.ks.fixedPositions;
            outputDeps.bBackground = obj.ks.bBackground;
            outputDeps.afeHashs = obj.ks.reqHashs;
            outputDeps.name = obj.ks.name;
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        %% -------------------------------------------------------------------------------
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

