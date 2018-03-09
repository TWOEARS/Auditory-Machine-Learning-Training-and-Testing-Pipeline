classdef AuditoryFrontEndConnection < matlab.mixin.SetGet
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        afeData;
        afeDataLength;
        SampleRate;
        bActive = false;
        Time = 0.0;
    end
    
    methods (Access = public)
        
        function obj = AuditoryFrontEndConnection(SampleRate)
            obj.SampleRate = SampleRate;
        end
        
        function [afeBlock, processedTime] = getSignal(obj, timeStep)
            
            % increase time
            obj.Time = obj.Time + timeStep;
            processedTime = obj.Time;
            
            % get data from current time until time+timestep
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = obj.afeData.keys
                afeSignal = obj.afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    afeSignalExtract = cell( size( afeSignal ) );
                    for ii = 1 : numel( afeSignal )
                        afeSignalExtract{ii} = ...
                            afeSignal{ii}.cutSignalCopyReducedToArray( timeStep, obj.afeDataLength - obj.Time);
                    end
                else
                    afeSignalExtract = ...
                        afeSignal.cutSignalCopyReducedToArray( timeStep, obj.afeDataLength - obj.Time);
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
            end
            
            fprintf('.');
            
            % if afeData ended go inactive
            if obj.Time >= obj.afeDataLength
                obj.bActive = false;
            end
            
        end
                
        % returns true if connection is active
        % necessary for running the blackboardSystem
        function b = isActive(obj)
            b = obj.bActive;
        end
        
        % sets the afeData, resets necessary parameters and activates the
        % connection
        function activate(obj, afeData)
            obj.afeData = afeData;
            anySignal = afeData(1);
            obj.afeDataLength = length(anySignal{1,1}.Data) / anySignal{1,1}.FsHz;
            obj.Time = 0.0;
            obj.bActive = true;
        end
                
    end
    
end

