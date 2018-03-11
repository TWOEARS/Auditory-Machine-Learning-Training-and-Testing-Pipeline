classdef BlackboardSystemWrapper < Core.IdProcInterface
    %BLACKBOARDSYSTEMWRAPPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        bbs;
        output;
    end
    
    methods (Access = public)
        
        function obj = BlackboardSystemWrapper(bbs)
            % init
            obj = obj@Core.IdProcInterface();
            % set blackboardSystem
            obj.bbs = bbs;
        end
        
        function process( obj, wavFilepath )
            % reset blackboard and KSs
            obj.bbs.blackboard.deleteData();
            warning('off','BB:tNotIncreasing');
            obj.bbs.blackboard.setSoundTimeIdx(0);
            warning('on','BB:tNotIncreasing');
            for ks = obj.bbs.blackboard.KSs 
                ks{1}.timeStamp();
            end
            % load AFE data
            in = obj.loadInputData( wavFilepath, 'afeData');
            % give input to AFE-Connection
            obj.bbs.robotConnect.activate(in.afeData);
            % run blackboardSystem
            obj.bbs.run();
            % make feature signals
            proc = emptyProc( 1 / obj.bbs.dataConnect.timeStep );
            data = [];
            fList = [];
            for val = obj.bbs.blackboard.data.values
                idHyp = val{1}.('identityHypotheses');
                data = [data; idHyp.p];
                if isempty(fList)
                    fList = {idHyp.label};
                end
            end
            featureSignal = FeatureSignal(proc, [], 'mono', data, fList);
            % save blackboard of blackboardSystem as output
            obj.output.blackboardData = featureSignal;                    
        end
                
        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            outFilepath = obj.getOutputFilepath( wavFilepath );
            obj.outFileSema = setfilesemaphore( outFilepath, 'semaphoreOldTime', 30 );
            out = obj.loadInputData( wavFilepath, varargin{:});
            out.afeData(out.afeData.Count+1) = load( outFilepath, varargin{:} );
            removefilesemaphore( obj.outFileSema );
        end                
    end
    
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.timeStep = obj.bbs.dataConnect.timeStep;
            %outputDeps.ksHashs = obj.bbs.blackboard.KSs;
            %outputDeps.bindHashs = obj.bbs.blackboardMonitor.listeners;                             
        end
        
        function out = getOutput( obj, varargin )
            out = obj.output;
        end
    end
    
end

