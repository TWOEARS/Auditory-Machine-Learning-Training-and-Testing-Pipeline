classdef BlackboardSystemWrapper < Core.IdProcInterface
    %BLACKBOARDSYSTEMWRAPPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        bbs;
        output;
        featureCreator;
        ksHashs;
        bindHashs;
    end
    
    methods (Access = public)
        
        function obj = BlackboardSystemWrapper(bbs, featureCreator)
            % init
            obj = obj@Core.IdProcInterface();
            % set blackboardSystem
            obj.bbs = bbs;
            obj.featureCreator = featureCreator;
            obj.ksHashs = calcDataHash(obj.bbs.blackboard.KSs);
            obj.bindHashs = calcDataHash(obj.bbs.blackboardMonitor.listeners);            
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
            % save blackboard data of blackboardSystem as output
            obj.output.blackboardData = obj.bbs.blackboard.data;                    
        end
                
        function [out, outFilepath] = loadProcessedData( obj, wavFilepath, varargin )
            [tmpOut, outFilepath] = loadProcessedData@Core.IdProcInterface( ...
                                                           obj, wavFilepath, 'blackboardData' );
            if any( strcmpi( 'afeData', varargin ) )
                out = obj.loadInputData( wavFilepath, 'afeData' , 'annotations');
                afeKeys = out.afeData.keys;
                bbsKeys = afeKeys(obj.bbs.dataConnect.afeDataIndexOffset+1:length(afeKeys));
                out.afeData.remove(bbsKeys);
                out.afeData(out.afeData.Count+1) = obj.makeFeatureSignal(tmpOut.blackboardData);
            elseif any( strcmpi( 'annotations', varargin ) )
                out = obj.loadInputData( wavFilepath, 'annotations');
                out.afeData = obj.makeFeatureSignal(tmpOut.blackboardData);
            else            
                out = tmpOut;
            end
        end                
    end
    
    methods (Access = protected)
        
        function outputDeps = getInternOutputDependencies( obj )
            outputDeps.ksHashs = obj.ksHashs;
            outputDeps.bindHash = obj.bindHashs;                             
        end
        
        function out = getOutput( obj, varargin )
            out = obj.output;
        end
        
        function featureSignal = makeFeatureSignal( obj , blackboardData)
            proc = emptyProc( 1 / obj.bbs.dataConnect.timeStep );
            data = [];
            fList = [];
            for val = blackboardData.values                
                [featureSigVal, fList] = obj.featureCreator.blackboardVal2FeatureSignalVal(val{1});
                data = [data; featureSigVal];
            end
            featureSignal = FeatureSignal(proc, [], 'mono', data, fList);
        end
    end
    
end

