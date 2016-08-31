classdef FeatureSetNSrc < FeatureCreators.Base
    % FeatureSetNSrc Specifies a feature set consisting of:
    %   ILD, ITD
    
    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        nFreqChannels;  % # of frequency channels
        wSizeSec;       % window size in seconds
        hSizeSec;       % window step size in seconds
        maxDelaySec;    % maximum cross-correleation delay
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSetNSrc( )
            obj = obj@FeatureCreators.Base();
            obj.nFreqChannels = 32;
            obj.wSizeSec = 0.02;
            obj.hSizeSec = 0.01;
            obj.maxDelaySec = 0.0011;
        end
        %% ----------------------------------------------------------------
        
        function afeRequests = getAFErequests( obj )
            % parameters
            params = genParStruct(...
                'cc_wSizeSec', obj.wSizeSec, ...
                'cc_hSizeSec', obj.hSizeSec, ...
                'cc_maxDelaySec', obj.maxDelaySec, ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 8000, ...
                'fb_nChannels', obj.nFreqChannels, ...
                'ihc_method', 'halfwave', ...
                'ild_wSizeSec', obj.wSizeSec, ...
                'ild_hSizeSec', obj.hSizeSec ...
                );
            
            % internaural level differences
            afeRequests{1}.name = 'ild';
            afeRequests{1}.params = params;
            
            % internaural time differences
            afeRequests{2}.name = 'itd';
            afeRequests{2}.params = params;
        end
        %% ----------------------------------------------------------------
        
        function x = constructVector( obj )
            % constructVector from features
            %   #1: ILD, #2: ITD
            %
            %   See getAFErequests
            
            % afeIdx 1: ILD
            ild = obj.makeBlockFromAfe( 1, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            x = obj.reshape2featVec( ild );
            
            % afeIdx 2: ITD
            itd = obj.makeBlockFromAfe( 2, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel)}, ...
                {@(a)(strcat('t', arrayfun(@(t)(num2str(t)),1:size(a.Data,1),'UniformOutput',false)))}, ...
                {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            x = obj.concatFeats( x, obj.reshape2featVec( itd ) );
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            % relevant members
            outputDeps.nFreqChannels = obj.nFreqChannels;
            outputDeps.wSizeSec = obj.wSizeSec;
            outputDeps.hSizeSec = obj.hSizeSec;
            outputDeps.maxDelaySec = obj.maxDelaySec;
            % classname
            classInfo = metaclass( obj );
            classnames = strsplit( classInfo.Name, '.' );
            outputDeps.featureProc = classnames{end};
            % version
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end
