classdef BAC_NS_NPP_Weighter < ImportanceWeighters.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
%         labelWeights;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC_NS_NPP_Weighter( labelWeights )
            obj = obj@ImportanceWeighters.Base();
%             if nargin >= 1
%                 obj.labelWeights = labelWeights;
%             end
        end
        % -----------------------------------------------------------------
    
        function [importanceWeights] = getImportanceWeights( obj, sampleIds )
            importanceWeights = ones( size( sampleIds ) );
            y = obj.data(:,'y');
            y = y(sampleIds,:);
            assert( size( y, 2 ) == 1 );
            ba = obj.data(:,'blockAnnotations');
            ba = ba(sampleIds);
            ba_ns = cat( 1, ba.nActivePointSrcs );
            ba_pp = cat( 1, ba.posPresent );
            clear ba;
            y_ = y .* (ba_ns+1) .* (1 + ~ba_pp * 9);
            y_unique = unique( y_ );
            lw = []; lwp = []; lwn = [];
            for ii = 1 : numel( y_unique )
                y_unique_ii_lidxs = y_ == y_unique(ii);
                lw(end+1) = numel( sampleIds ) / sum( y_unique_ii_lidxs ); %#ok<AGROW>
                if y_unique(ii) > 0
                    lwp(end+1) = lw(end); %#ok<AGROW>
                else
                    lwn(end+1) = lw(end); %#ok<AGROW>
                end
            end
            for ii = 1 : numel( lw )
                y_unique_ii_lidxs = y_ == y_unique(ii);
                if y_unique(ii) > 0
                    % because there is p vs (npp+nnp)
                    lw(ii) = lw(ii) * sum(lwn)/sum(lwp); %#ok<AGROW> 
                end
                importanceWeights(y_unique_ii_lidxs) = lw(ii);
            end
            importanceWeights = importanceWeights / min( importanceWeights );
            obj.verboseOutput = '\nWeighting samples of \n';
            for ii = 1 : numel( y_unique )
                trueLabel = unique( y(y_==y_unique(ii)) );
                labelWeight = unique( importanceWeights(y_==y_unique(ii)) );
                obj.verboseOutput = sprintf( ['%s' ...
                                              '  class %d (%d) with %f\n'], ...
                                             obj.verboseOutput, ...
                                             y_unique(ii), trueLabel, labelWeight );
            end
        end
        % -----------------------------------------------------------------

    end

end

