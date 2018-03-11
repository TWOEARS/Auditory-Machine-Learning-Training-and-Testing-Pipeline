classdef BlackboardSystemWrapper < Core.IdProcInterface
    %BLACKBOARDSYSTEMWRAPPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        bbs;
        output;
    end
    
    methods (Access = public)
        
        % Constructor
        function obj = BlackboardSystemWrapper(bbs)
            % init
            obj = obj@Core.IdProcInterface();
            % set blackboardSystem
            obj.bbs = bbs;
        end
        
        % process
        function process( obj, wavFilepath )
            % reset blackboard
            obj.bbs.blackboard.deleteData();
            obj.bbs.blackboard.setSoundTimeIdx(0);
            % load AFE data
            in = obj.loadInputData( wavFilepath, 'afeData');
            % give input to AFE-Connection
            obj.bbs.robotConnect.activate(in.afeData);
            % run blackboardSystem
            obj.bbs.run();
            % TODO: make feature signals
            FsHz = 1 / obj.bbs.dataConnect.timeStep;
            data = [];
            for val = obj.bbs.blackboard.data.values
                idHyp = val{1}.('identityHypotheses');
                data = [data; idHyp.p];
            end
            keys = obj.bbs.blackboard.data.keys;
            fList = {obj.bbs.blackboard.data(keys{1}).identityHypotheses.label};
            featureSignal = FeatureSignal([], [], 'mono', data, fList);
            featureSignal.FsHz = FsHz;
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
            % TODO!
            outputDeps.timeStep = obj.bbs.dataConnect.timeStep;
            %
        end
        
        function out = getOutput( obj, varargin )
            out = obj.output;
        end
    end
    
end

