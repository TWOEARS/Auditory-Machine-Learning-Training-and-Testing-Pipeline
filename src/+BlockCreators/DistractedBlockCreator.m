classdef DistractedBlockCreator < BlockCreators.StandardBlockCreator
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
        distractorIdxs;
        rejectThreshold;
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = DistractedBlockCreator( blockSize_s, shiftSize_s, varargin )
            obj = obj@BlockCreators.StandardBlockCreator( blockSize_s, shiftSize_s );
            ip = inputParser;
            ip.addOptional( 'distractorSources', 2 );
            ip.addOptional( 'rejectEnergyThreshold', -30 );
            ip.parse( varargin{:} );
            obj.distractorIdxs = ip.Results.distractorSources;
            obj.rejectThreshold = ip.Results.rejectEnergyThreshold;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% ----------------------------------------------------------------------------------- 
    methods (Access = protected)
        
        function outputDeps = getBlockCreatorInternOutputDependencies( obj )
            outputDeps.sbc = getBlockCreatorInternOutputDependencies@...
                                                BlockCreators.StandardBlockCreator( obj );
            outputDeps.v = 1;
        end
        %% ------------------------------------------------------------------------------- 

        function [afeBlocks, blockAnnots] = blockify( obj, afeData, annotations )
            [afeBlocks, blockAnnots] = ...
                 blockify@BlockCreators.StandardBlockCreator( obj, afeData, annotations );
            for ii = numel( afeBlocks ) : -1 : 1
                eFrames = cellfun( @(e)( e(obj.distractorIdxs,:) ), ...
                            blockAnnots(ii).srcEnergy.srcEnergy, 'UniformOutput', false );
                distractorEnergy  = -log( -mean( cell2mat( eFrames ), 2 ) );
                rejectBlock = sum( log( -obj.rejectThreshold ) + distractorEnergy ) < 0;
                if rejectBlock
                    afeBlocks(ii) = [];
                    blockAnnots(ii) = [];
                end
                fprintf( '*' );
            end
        end
        %% -------------------------------------------------------------------------------
        
    end
    %% ----------------------------------------------------------------------------------- 
    
    methods (Static)
        
        %% ------------------------------------------------------------------------------- 
        %% ------------------------------------------------------------------------------- 
        
    end
    
end

        

