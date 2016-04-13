classdef MultiLabeler < LabelCreators.Base
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        individualLabelers;
        throwAwayZeroLabelBlocks;
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = public)
        
        function obj = MultiLabeler( individualLabelers, throwAwayZeroLabelBlocks )
            obj = obj@LabelCreators.Base();
            obj.individualLabelers = individualLabelers;
            if ~exist( 'throwAwayZeroLabelBlocks', 'var' )
                throwAwayZeroLabelBlocks = false;
            end
            obj.throwAwayZeroLabelBlocks = throwAwayZeroLabelBlocks;
        end
        %% -------------------------------------------------------------------------------
        
    end

    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function y = label( obj, blockAnnotations )
            for ii = 1 : numel( obj.individualLabelers )
                y(1,ii) = obj.individualLabelers{ii}.label( blockAnnotations );
            end
        end
        %% -------------------------------------------------------------------------------

        % override of LabelCreators.Base's method
        function out = getOutput( obj )
            out = getOutput@LabelCreators.Base( obj );
            if obj.throwAwayZeroLabelBlocks
                out.x = out.x(all(out.y ~= 0));
                out.a = out.blockAnnotations(all(out.y ~= 0));
                out.y = out.y(all(out.y ~= 0));
            end
        end
        %% -------------------------------------------------------------------------------

        function outputDeps = getLabelInternOutputDependencies( obj )
            for ii = 1 : numel( obj.individualLabelers )
                outDepName = sprintf( 'labeler%d', ii );
                outputDeps.(outDepName) = ...
                              obj.individualLabelers{ii}.getLabelInternOutputDependencies;
            end
            outputDeps.v = 1;
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end
