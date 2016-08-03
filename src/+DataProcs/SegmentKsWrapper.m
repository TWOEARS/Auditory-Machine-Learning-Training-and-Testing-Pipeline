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
        
        function obj = SegmentKsWrapper( name, varargin )
            segmentKs = SegmentationKS( name, varargin{:} );
            obj = obj@DataProcs.BlackboardKsWrapper( segmentKs );
        end
        %% -------------------------------------------------------------------------------
        
        function preproc( obj, blockAnnotations )
            prior = zeros( size( 1, obj.ks.nSources ) );
            for ii = 1 : obj.ks.nSources
                azm = blockAnnotations.srcAzms(ii);
                prior(ii) = deg2rad( azm );
                if prior(ii) > pi, prior(ii) = -deg2rad( azm ); end
            end
            obj.ks.setFixedPositions( prior );
        end
        %% -------------------------------------------------------------------------------
        
        function postproc( obj, afeData, blockAnnotations )
            segHypos = obj.bbs.blackboard.getLastData( 'segmentationHypotheses' );
            for ii = 1 : numel( segHypos.data )
                obj.out.afeBlocks{end+1,1} = obj.softmaskAFE( afeData, segHypos, ii );
                if isempty(obj.out.blockAnnotations)
                    obj.out.blockAnnotations = obj.maskBA( blockAnnotations, ii );
                else
                    obj.out.blockAnnotations(end+1,1) = obj.maskBA( blockAnnotations, ii );
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function outputDeps = getKsInternOutputDependencies( obj )
            outputDeps.v = 2;
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
        
        function afeBlock = softmaskAFE( obj, afeBlock, segHypos, idx_mask )
            afeBlock = SegmentIdentityKS.maskAFEData( afeBlock, ...
                                                      segHypos.data(idx_mask).softMask, ...
                                                      segHypos.data(idx_mask).cfHz, ...
                                                      segHypos.data(idx_mask).hopSize );
        end
        %% -------------------------------------------------------------------------------
        
        function blockAnnotations = maskBA( obj, blockAnnotations, srcIdx )
            baFields = fieldnames( blockAnnotations );
            for ff = 1 : numel( baFields )
                if isstruct( blockAnnotations.(baFields{ff}) )
                    baIsSrcIdEq = ...
                          [blockAnnotations.(baFields{ff}).(baFields{ff}){:,2}] == srcIdx;
                    blockAnnotations.(baFields{ff}).t.onset(~baIsSrcIdEq) = [];
                    blockAnnotations.(baFields{ff}).t.offset(~baIsSrcIdEq) = [];
                    blockAnnotations.(baFields{ff}).(baFields{ff})(~baIsSrcIdEq,:) = [];
                    blockAnnotations.(baFields{ff}).(baFields{ff})(:,2) = ...
                                                   repmat( {1}, sum( baIsSrcIdEq ), 1 );
                elseif iscell( blockAnnotations.(baFields{ff}) ) ...
                        || numel( blockAnnotations.(baFields{ff}) ) > 1
                    baIsSrcIdEq = false( size( blockAnnotations.(baFields{ff}) ) );
                    baIsSrcIdEq(srcIdx) = true;
                    blockAnnotations.(baFields{ff})(~baIsSrcIdEq) = [];
                end
            end
            blockAnnotations.mixEnergy = blockAnnotations.srcEnergy{1};
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% -----------------------------------------------------------------------------------
    
    methods (Static)
        
        %% -------------------------------------------------------------------------------
        
    end
    
end

        

