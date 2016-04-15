classdef IdentificationTrainingPipeline < handle
    % IdentificationTrainingPipeline The identification training pipeline
    %   facilitates training models for classifying sounds.
    %   It manages the data for training and testing, orchestrates feature
    %   extraction, optimizes the model and produces performance metrics 
    %   for evaluating a model.
    %   Trained models can then be integrated into the blackboard system
    %   by loading them in an identitiy knowledge source
    %
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        trainer;
        generalizationPerfomanceAssessCVtrainer; % k-fold cross validation
        dataPipeProcs;
        data;       
        trainSet;
        testSet;
        cacheSystemDir;
        nPathLevelsForCacheName;
    end
    
    %% -----------------------------------------------------------------------------------
    properties 
        blockCreator;
        featureCreator; % feature extraction
        verbose = true; % log level
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Static)
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdentificationTrainingPipeline( varargin )
            ip = inputParser;
            ip.addOptional( 'cacheSystemDir', [getMFilePath() '/../../idPipeCache'] );
            ip.addOptional( 'nPathLevelsForCacheName', 3 );
            ip.parse( varargin{:} );
            obj.cacheSystemDir = ip.Results.cacheSystemDir;
            obj.nPathLevelsForCacheName = ip.Results.nPathLevelsForCacheName;
            obj.dataPipeProcs = {};
            obj.data = core.IdentTrainPipeData();
            obj.trainSet = core.IdentTrainPipeData();
            obj.testSet = core.IdentTrainPipeData();
        end
        %% ------------------------------------------------------------------------------- 
        
        function addModelCreator( obj, trainer )
            if ~isa( trainer, 'modelTrainers.Base' )
                error( 'ModelCreator must be of type modelTrainers.Base' );
            end
            obj.trainer = trainer;
            obj.generalizationPerfomanceAssessCVtrainer = modelTrainers.CVtrainer( obj.trainer );
        end
        %% ------------------------------------------------------------------------------- 
        
        function resetDataProcs( obj )
            obj.dataPipeProcs = {};
        end
        %% ------------------------------------------------------------------------------- 

        function addDataPipeProc( obj, idProc )
            if ~isa( idProc, 'core.IdProcInterface' )
                error( 'idProc must be of type core.IdProcInterface.' );
            end
            idProc.setCacheSystemDir( obj.cacheSystemDir, obj.nPathLevelsForCacheName );
            idProc.connectIdData( obj.data );
            dataPipeProc = core.DataPipeProc( idProc ); 
            dataPipeProc.init();
            dataPipeProc.connectData( obj.data );
            obj.dataPipeProcs{end+1} = dataPipeProc;
        end
        %% ------------------------------------------------------------------------------- 
        
        function connectData( obj, data )
            obj.data = data;
        end
        %% ------------------------------------------------------------------------------- 

        function setTrainData( obj, trainData )
            obj.trainSet = trainData;
            obj.data = core.IdentTrainPipeData.combineData( obj.trainSet, obj.testSet );
        end
        %% ------------------------------------------------------------------------------- 
        
        function setTestData( obj, testData )
            obj.testSet = testData;
            obj.data = core.IdentTrainPipeData.combineData( obj.trainSet, obj.testSet );
        end
        %% ------------------------------------------------------------------------------- 
        
        function splitIntoTrainAndTestSets( obj, trainSetShare )
            [obj.trainSet, obj.testSet] = obj.data.getShare( trainSetShare );
        end
        %% ------------------------------------------------------------------------------- 
        
        %% function run( obj, modelname, nGenAssessFolds )
        %       Runs the pipeline, creating the models specified in models
        %       All models trained in one run use the same training and
        %       test sets.
        %
        %   modelname: name for model.
        %              no training options:
        %              'onlyGenCache' stops after data processing
        %              'dataStore' saves data in native format
        %              'dataStoreUni' saves data as x,y matrices
        %           
        %   nGenAssessFolds: number of folds of generalization assessment
        %   cross validation (default: 0 - no folds)
        %
        function modelPath = run( obj, modelname, nGenAssessFolds )
            if nargin < 3
                nGenAssessFolds = 0;
            end
            cleaner = onCleanup( @() obj.finish() );
            modelPath = obj.createFilesDir();
            
            for ii = 2 : length( obj.dataPipeProcs )
                obj.dataPipeProcs{ii}.connectToOutputFrom( obj.dataPipeProcs{ii-1} );
            end
            successiveProcFileList = [];
            for ii = length( obj.dataPipeProcs ) : -1 : 1
                obj.dataPipeProcs{ii}.checkDataFiles( successiveProcFileList );
                successiveProcFileList = obj.dataPipeProcs{ii}.fileListOverlay;
            end
            for ii = 1 : length( obj.dataPipeProcs )
                obj.dataPipeProcs{ii}.run();
            end
            
            if strcmp(modelname, 'onlyGenCache'), return; end;
            
            featureCreator = obj.featureCreator;
            lastDataProcParams = ...
                obj.dataPipeProcs{end}.dataFileProcessor.getOutputDependencies();
            if strcmp(modelname, 'dataStore')
                data = obj.data;
                save( 'dataStore.mat', ...
                      'data', 'featureCreator', 'lastDataProcParams', '-v7.3' );
                return; 
            elseif strcmp(modelname, 'dataStoreUni')
                x = obj.data(:,'x');
                y = obj.data(:,'y');
                featureNames = obj.featureCreator.description;
                save( 'dataStoreUni.mat', ...
                      'x', 'y', 'featureNames', '-v7.3' );
                return; 
            end;
            
            fprintf( ['\n\n===================================\n',...
                          '##   Training model "%s"\n',...
                          '===================================\n\n'], modelname );
            if nGenAssessFolds > 1
                fprintf( '\n==  Generalization performance assessment CV...\n\n' );
                obj.generalizationPerfomanceAssessCVtrainer.setNumberOfFolds( nGenAssessFolds );
                obj.generalizationPerfomanceAssessCVtrainer.setData( obj.trainSet );
                obj.generalizationPerfomanceAssessCVtrainer.run();
                genPerfCVresults = obj.generalizationPerfomanceAssessCVtrainer.getPerformance();
                fprintf( '\n==  Performance after generalization assessment CV:\n' );
                disp( genPerfCVresults );
            end
            obj.trainer.setData( obj.trainSet, obj.testSet );
            fprintf( '\n==  Training model on trainSet...\n\n' );
            tic;
            obj.trainer.run();
            trainTime = toc;
            testTime = nan;
            testPerfresults = [];
            if ~isempty( obj.testSet )
                fprintf( '\n==  Testing model on testSet... \n\n' );
                tic;
                testPerfresults = obj.trainer.getPerformance( 'datapointInfo' );
                testTime = toc;
                if numel( testPerfresults ) == 1
                    fprintf( ['\n\n===================================\n',...
                              '##   "%s" Performance: %f\n',...
                              '===================================\n\n'], ...
                             modelname, testPerfresults.double() );
                else
                    fprintf( ['\n\n===================================\n',...
                              '##   "%s" Performance: more than one value\n',...
                              '===================================\n\n'], ...
                             modelname );
                end
            end
            model = obj.trainer.getModel();
            modelFilename = [modelname '.model.mat'];
            save( modelFilename, ...
                'model', 'featureCreator', ...
                'testPerfresults', 'trainTime', 'testTime', 'lastDataProcParams' );
        end
        
        %% -------------------------------------------------------------------------------
        
        function finish( obj )    
            diary off;
            cd( '..' );
        end
        %% -------------------------------------------------------------------------------

        function path = createFilesDir( obj )
            curTimeStr = buildCurrentTimeString();
            saveDir = ['Training' curTimeStr];
            mkdir( saveDir );
            cd( saveDir );
            path = pwd;
            diary( ['IdTrainPipe' curTimeStr '.log'] );
            obj.trainSet.saveDataFList( ['trainSet' curTimeStr '.flist'], 'sound_databases' );
            if ~isempty( obj.testSet )
                obj.testSet.saveDataFList( ['testSet' curTimeStr '.flist'], 'sound_databases' );
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = private)
    end
    
end

