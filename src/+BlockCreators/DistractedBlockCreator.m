classdef DistractedBlockCreator < BlockCreators.StandardBlockCreator
    % 
    %% ----------------------------------------------------------------------------------- 
    properties (SetAccess = private)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = DistractedBlockCreator( blockSize_s, shiftSize_s, varargin )
            obj = obj@BlockCreators.StandardBlockCreator( blockSize_s, shiftSize_s );
            ip = inputParser;
            ip.addOptional( 'distractorSources', 2 );
            ip.addOptional( 'rejectEnergyThreshold', -30 );
            ip.parse( varargin{:} );
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
            [afeBlocks, blockAnnots] = ...
                 blockify@BlockCreators.StandardBlockCreator( obj, afeData, annotations );
            for ii = numel( afeBlocks ) : -1 : 1
                eFrames = cellfun( @(e)( e(obj.distractorIdxs,:) ), ...
                            blockAnnots(ii).srcEnergy.srcEnergy, 'UniformOutput', false );
                distractorEnergy  = -log( -mean( cell2mat( eFrames ), 2 ) );
                rejectBlock = sum( log( -rejectThreshold ) + distractorEnergy ) < 0;
                if rejectBlock
                    afeBlocks(ii) = [];
                    blockAnnots(ii) = [];
                end
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

        

