classdef AuditoryFrontEndBridgeKS < AbstractKS
    %AUDITORYFRONTENDBRIDGEKS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        reqHashs;                       % all unique requestHashs from the blackboard's KSs
        requests;                       % all unique requests from the blackboard's KSs
        robotInterfaceObj;              % Scene simulator object
        timeStep;                       % basic time step in s, i.e. update rate
    end
    
    properties (SetAccess = public)
        afeDataIndexOffset;             % number of AFE requests that do not originate from the BBS
    end
    
    
    methods (Access = public)
        
        % constructor
        function obj = AuditoryFrontEndBridgeKS(robotInterfaceObj, timeStep)
            % inherit everything but ignor managerObject (will be set to []
            % by MATLAB default)
            obj = obj@AbstractKS();
            obj.robotInterfaceObj = robotInterfaceObj;
            if nargin < 3 || isempty( timeStep )
                obj.timestep = 1.0;
            end
            obj.timeStep = timeStep;
            obj.invocationMaxFrequency_Hz = inf;
            obj.reqHashs = [];
            obj.requests = [];
            obj.afeDataIndexOffset = 0;
        end
        
        
        %% KS logic
        function [bExecute, bWait] = canExecute(obj)
            bExecute = obj.robotInterfaceObj.isActive();
            bWait = false;
        end
        
        % execution
        function obj = execute(obj)
            % Get AFE data from AFE connections
            [afeSignal, processedTime] = obj.robotInterfaceObj.getSignal(obj.timeStep);
            for i = 1 : length(obj.reqHashs)
                % append data to blackboard
                hash = obj.reqHashs(i);
                obj.blackboard.addSignal(hash{1}, afeSignal(i + obj.afeDataIndexOffset));
            end
            obj.blackboard.advanceSoundTimeIdx(processedTime);
            obj.blackboard.addData('headOrientation', 0);
            % Trigger event
            notify(obj, 'KsFiredEvent');
        end
        
        % override Proc creation
        function createProcsForDepKS(obj, auditoryFrontEndDepKs)
            if isempty(obj.reqHashs)
                obj.reqHashs = auditoryFrontEndDepKs.reqHashs;
                obj.requests = auditoryFrontEndDepKs.requests;
            else
                for i = 1: numel(auditoryFrontEndDepKs.requests)
                    if ~ismember(auditoryFrontEndDepKs.reqHashs(i), obj.reqHashs)
                        obj.reqHashs = [obj.reqHashs auditoryFrontEndDepKs.reqHashs(i)];
                        obj.requests = [obj.requests auditoryFrontEndDepKs.requests(i)];
                    end
                end
            end
        end
        
    end
    
end

