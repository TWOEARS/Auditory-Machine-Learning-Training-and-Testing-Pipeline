classdef AuditoryFrontEndConnection
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        afeData;
        afeDataLength;
        SampleRate;
        bActive = false;
        Time = 0.0;
    end
    
    methods
        
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
                            afeSignal{ii}.cutSignalCopy( timeStep, obj.afeDateLength + obj.Time);
                    end
                else
                    afeSignalExtract = ...
                        afeSignal.cutSignalCopy( timeStep, obj.afeDataLength + obj.Time);
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
            end
            
            % if afeData ended go inactive
            if obj.Time >= obj.afeDataLength
                bActive = false;
            end
            
        end
        
        % returns true if connection is active
        % necessary for running the blackboardSystem
        function b = isActive(obj)
            b = obj.bActive;
        end
        
        % sets the afeData, resets necessary parameters and activates the
        % connection
        function obj = setAfeData(obj, afeData)
            obj.afeData = afeData;
            obj.afeDataLength = length(afeData) / obj.SampleRate;
            obj.Time = 0.0;
            obj.bActive = true;
        end
        
        
    end
    
end

