classdef BlackboardSystemWrapper < Core.IdProcInterface
    %BLACKBOARDSYSTEMWRAPPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
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
            % load AFE data
            in = obj.loadInputData( wavFilepath, 'afeData');
            % give input to AFE-Connection
            obj.bbs.robotConnect.setAfeData(in);
            % run blackboardSystem
            obj.bbs.run();
            % save blackboard of blackboardSystem as output
            obj.output.blackboardData = obj.bbs.blackboard;       
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
        end
        
        function out = getOutput( obj, varargin )
            out = obj.output;
        end        
    end
    
end

