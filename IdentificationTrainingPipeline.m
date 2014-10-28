classdef IdentificationTrainingPipeline < handle

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        trainer;
        generalizationPerfomanceAssessCVtrainer;
        dataPipeProcs;
        gatherFeaturesProc;
        data;       
        trainSet;
        testSet;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        %% Constructor.
        function obj = IdentificationTrainingPipeline()
            obj.data = IdentTrainPipeData();
            obj.dataPipeProcs = {};
        end
        %% ----------------------------------------------------------------
        
        %   -----------------------
        %   setting up the pipeline
        %   -----------------------
        function addModelCreator( obj, trainer )
            if ~isa( trainer, 'IdTrainerInterface' )
                error( 'ModelCreator must be of type IdTrainerInterface.' );
            end
            obj.trainer = trainer;
            obj.generalizationPerfomanceAssessCVtrainer = CVtrainer( obj.trainer );
        end
        %% ----------------------------------------------------------------
        
        function addDataPipeProc( obj, dataProc )
            if ~isa( dataProc, 'IdProcInterface' )
                error( 'dataProc must be of type IdProcInterface.' );
            end
            dataPipeProc = DataPipeProc( dataProc ); 
            dataPipeProc.connectData( obj.data );
            obj.dataPipeProcs{end+1} = dataPipeProc;
        end
        %% ----------------------------------------------------------------
        
        function addGatherFeaturesProc( obj, gatherFeaturesProc )
            gatherFeaturesProc.connectData( obj.data );
            obj.gatherFeaturesProc = gatherFeaturesProc;
        end
        %% ----------------------------------------------------------------
        
        %   -------------------
        %   setting up the data
        %   -------------------
        function loadWavFileList( obj, wavflist )
            if ~isa( wavflist, 'char' )
                error( 'wavflist must be a string.' );
            elseif ~exist( wavflist, 'file' )
                error( 'Wavflist not found.' );
            end
            fid = fopen( wavflist );
            wavs = textscan( fid, '%s' );
            for k = 1:length(wavs{1})
                wavName = wavs{1}{k};
                if ~exist( wavName, 'file' )
                    error ( 'Could not find %s listed in %s.', wavName, wavflist );
                end
                wavName = which( wavName ); % ensure absolute path
                wavClass = IdEvalFrame.readEventClass( wavName );
                obj.data(wavClass,'+') = wavName;
            end
            fclose( fid );
        end
        %% ----------------------------------------------------------------
        
        %   --------------------
        %   running the pipeline
        %   --------------------

        %% function run( obj, models, trainSetShare )
        %       Runs the pipeline, creating the models specified in models
        %       All models trained in one run use the same training and
        %       test sets.
        %
        %   models: 'all' for all training data classes (but not 'general')
        %           cell array of strings with model names for particular
        %           set of models
        %   trainSetShare:  value between 0 and 1. testSet gets share of
        %                   1 - trainSetShare.
        function run( obj, models, trainSetShare )
            if strcmpi( models, 'all' )
                models = obj.data.classNames;
                models(strcmp('general', models)) = [];
            end

            for ii = 1 : length( obj.dataPipeProcs )
                if ii > 1
                    obj.dataPipeProcs{ii}.connectToOutputFrom( obj.dataPipeProcs{ii-1} );
                end
                obj.dataPipeProcs{ii}.run();
            end
            obj.gatherFeaturesProc.connectToOutputFrom( obj.dataPipeProcs{end} );
            obj.gatherFeaturesProc.run();

            obj.createTrainTestSplit( trainSetShare );
            
            for model = models
                obj.generalizationPerfomanceAssessCVtrainer.setData( obj.trainSet );
                obj.generalizationPerfomanceAssessCVtrainer.setPositiveClass( model{1} );
                obj.generalizationPerfomanceAssessCVtrainer.run();
                genPerfCVresults = obj.generalizationPerfomanceAssessCVtrainer.getPerformance();
                obj.trainer.setData( obj.trainSet, obj.testSet );
                obj.trainer.setPositiveClass( model{1} );
                obj.trainer.run();
                trainPerfresults = obj.trainer.getPerformance();
                model = obj.trainer.getModel();
            end;
            
        end
        %% ----------------------------------------------------------------
        
        function createTrainTestSplit( obj, trainSetShare )
            gcdShares = gcd( round( 100 * trainSetShare ), round( 100 * (1 - trainSetShare) ) ) / 100;
            nFolds = round( 1 / gcdShares );
            folds = obj.data.splitInPermutedStratifiedFolds( nFolds );
            obj.trainSet = IdentTrainPipeData.combineData( folds{1:round(nFolds*trainSetShare)} );
            if round( nFolds * (1-trainSetShare) ) > 0
                obj.testSet = IdentTrainPipeData.combineData( folds{round(nFolds*trainSetShare)+1:end} );
            else
                obj.testSet = [];
            end
        end
        %% ----------------------------------------------------------------
        

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end

% function produceModel( soundsDir, className, esetup )
% 
% %% start debug output
% 
% modelSavePreStr = [soundsDir '/' className '/' className '_' getModelHash(esetup)];
% delete( [modelSavePreStr '.log'] );
% diary( [modelSavePreStr '.log'] );
% disp('--------------------------------------------------------');
% disp('--------------------------------------------------------');
% flatPrintStruct( esetup )
% disp('--------------------------------------------------------');
% 
% %% split data for outer CV (generalization perfomance assessment)
% 
% [yfolds, xfolds, idsfolds] = splitDataPermutation( yTrain, xTrain, idsTrain, esetup.generalizationEstimation.folds );
% 
% %% outer CV for estimating generalization performance
% 
% for i = 1:esetup.generalizationEstimation.folds
%     
%     foldsIdx = 1:esetup.generalizationEstimation.folds;
%     foldsIdx(i) = [];
%     
%     fprintf( '\n%i. run of generalization assessment CV -- training\n\n', i );
%     [model, translators, factors, predGenVals(i), hps{i}, cvtrVals(i)] = trainSvm( foldsIdx, yfolds, xfolds, idsfolds, esetup, 0 );
%     
%     fprintf( '\n%i. run of generalization assessment CV -- testing\n', i );
%     [~, genVals(i), ~] = libsvmPredictExt( yfolds{i}, xfolds{i}, model, translators, factors, 0 );
%     fprintf( '===============================================================\n' );
%     
% end
% 
% %% get perfomance numbers of outer CV
% 
% cvtrVal = mean( cvtrVals );
% cvtrValStd = std( cvtrVals );
% genVal = mean( genVals );
% genValStd = std( genVals );
% predGenVal = mean( predGenVals );
% predGenValStd = std( predGenVals );
% fprintf( '\n=============================================\n' );
% fprintf( '====================================================================================\n' );
% fprintf( '\nTraining perfomance as evaluated by %i-fold CV is %g +-%g\n', esetup.generalizationEstimation.folds, cvtrVal, cvtrValStd );
% fprintf( '\nGeneralization perfomance as evaluated by %i-fold CV is %g +-%g\n', esetup.generalizationEstimation.folds, genVal, genValStd );
% fprintf( 'Prediction of CV was %g +-%g\n\n', predGenVal, predGenValStd );
% fprintf( '====================================================================================\n' );
% fprintf( '=============================================\n' );
% 
% %% final production of a model, using the whole training dataset
% 
% disp( 'training model on whole training dataset' );
% [model, translators, factors, trPredGenVal, trHps, trVal] = trainSvm( 1:esetup.generalizationEstimation.folds, yfolds, xfolds, idsfolds, esetup, 1 );
% 
% %% test final model on test set, if split
% 
% if ~isempty( yTest )
%     fprintf( '\n\nPerfomance of final model on test set:\n', i );
%     [~, testVal, ~] = libsvmPredictExt( yTest, xTest, model, translators, factors, 1 );
%     fprintf( '===============================================================\n' );
% else
%     testVal = [];
% end
% 
% %% saving model and perfomance numbers, end debug output
% 
% modelhashes = {['wp2hash: ' getWp2dataHash( esetup )]; ['blockdatahash: ' getBlockDataHash( esetup )]; ['labelhash: ' getLabelsHash( esetup, dfiles )]; ['featureshash: ' getFeaturesHash( esetup, dfiles )]; ['modelhash: ' getModelHash( esetup )]}
% save( [modelSavePreStr '_model.mat'], 'model', 'genVal', 'genValStd', 'genVals', 'cvtrVal', 'cvtrValStd', 'cvtrVals', 'predGenVal', 'predGenValStd', 'predGenVals', 'trPredGenVal', 'trVal', 'testVal', 'hps', 'trHps', 'modelhashes', 'esetup' );
% save( [modelSavePreStr '_scale.mat'], 'translators', 'factors', 'esetup' );
% dynSaveMFun( @scaleData, [], [modelSavePreStr '_scaleFunction'] );
% dynSaveMFun( esetup.featureCreation.function, esetup.featureCreation.functionParam, [modelSavePreStr '_featureFunction.mat'] );
% 
% diary off;
% 
