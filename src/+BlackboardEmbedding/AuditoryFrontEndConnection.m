classdef AuditoryFrontEndConnection < matlab.mixin.SetGet
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        afeData;
        afeDataLength;
        bActive = false;
        Time = 0.0;
    end
    
    methods (Access = public)
        
        function obj = AuditoryFrontEndConnection()
        end
        
        function [afeBlock, processedTime] = getSignal(obj, timeStep)
                                    
            processedTime = [];
            tmpProcessedTime = obj.Time + timeStep;
            
            % get data from beginning of signal to current time
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = obj.afeData.keys
                afeSignal = obj.afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    afeSignalExtract = cell( size( afeSignal ) );
                    for ii = 1 : numel( afeSignal )
                        afeSignalExtract{ii} = ...
                            afeSignal{ii}.cutSignalCopyReducedToArray( tmpProcessedTime, obj.afeDataLength - tmpProcessedTime);
                    end
                    sigSize = size(afeSignalExtract{1}.Data);
                    processedTime = [ processedTime ... 
                        sigSize(1) / afeSignalExtract{1}.FsHz ];
                else
                    afeSignalExtract = ...
                        afeSignal.cutSignalCopyReducedToArray( tmpProcessedTime, obj.afeDataLength - tmpProcessedTime);
                    sigSize = size(afeSignalExtract.Data);
                    processedTime = [ processedTime ...
                        sigSize(1) / afeSignalExtract.FsHz ];

                end
                afeBlock(afeKey{1}) = afeSignalExtract;
            end
            
            % calculate the actual minimum processed time
            processedTime = min(processedTime);
            
            % increase time
            obj.Time = obj.Time + processedTime;
            
            % indicate processing
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
            afeDataLength = [];
            % calculate maximum AFE data time in s
            for afeKey = obj.afeData.keys
                afeSignal = obj.afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    % assumption: all channels are equally sized
                    sigSize = size(afeSignal{1}.Data);
                    afeDataLength = [ afeDataLength ...
                        sigSize(1) / afeSignal{1}.FsHz ];
                else
                    sigSize = size(afeSignal.Data);
                    afeDataLength = [ afeDataLength ...
                        sigSize(1) / afeSignal.FsHz ];
                end
            end
            obj.afeDataLength = max(afeDataLength);
            obj.Time = 0.0;
            obj.bActive = true;
        end
                
    end
    
end

