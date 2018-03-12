classdef SvmPcaModel < Models.PcaReducedModel
    
    %% --------------------------------------------------------------------
    properties (SetAccess = ?ModelTrainers.SVMtrainer)
        useProbModel;
        model;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = SvmPcaModel( expVarThres )
            if nargin < 1, expVarThres = 0.99; end
            obj = obj@Models.PcaReducedModel( expVarThres );
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function [y,score] = applyModelToReducedData( obj, x )
            yDummy = zeros( size( x, 1 ), 1 );
            [y, ~, score] = libsvmpredict( double( yDummy ), double( x ), obj.model, ...
                                           sprintf( '-q -b %d', obj.useProbModel ) );
            score = score(1);
        end
        %% -----------------------------------------------------------------

    end
    
end

