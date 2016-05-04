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
            prior = zeros( size( 1, obj.ks.nSources ) );
            for ii = 1 : obj.ks.nSources
                blockAzms = [blockAnnotations.srcAzms.srcAzms{:}];
                srcBlockAzms = blockAzms(ii,:);
                azm = median( srcBlockAzms );
                prior(ii) = deg2rad( azm );
                if prior(ii) > pi, prior(ii) = -deg2rad( azm ); end
            end
            obj.ks.setFixedPositions( prior );
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj, afeData, blockAnnotations )
            segHypos = obj.bbs.blackboard.getLastData( 'segmentationHypotheses' );
            segHypos = segHypos.data;
            for ii = 1 : numel( segHypos )
                obj.out.afeBlocks{end+1} = obj.softmaskAFE( afeData, segHypos(ii) );
                obj.out.blockAnnotations(end+1) = obj.maskBA( blockAnnotations, ii );
            end
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
        
        function afeBlocks = softmaskAFE( obj, afeBlock, segMask )
        end
        %% -------------------------------------------------------------------------------
        
        function blockAnnotations = maskBA( obj, blockAnnotations, srcIdx )
            baFields = fieldnames( blockAnnotations );
            for ff = 1 : numel( baFields )
                blockAnnotations.(baFields{ii}).(baFields{ii}) = ...
                         blockAnnotations.(baFields{ii}).(baFields{ii})(srcIdx,:,:,:,:,:);
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

