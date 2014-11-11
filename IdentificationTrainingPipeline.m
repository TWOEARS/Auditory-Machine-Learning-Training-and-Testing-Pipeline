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
    properties 
        featureCreator;
        verbose = true;
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

        %% function run( obj, models, trainSetShare, nGenAssessFolds )
        %       Runs the pipeline, creating the models specified in models
        %       All models trained in one run use the same training and
        %       test sets.
        %
        %   models: 'all' for all training data classes (but not 'general')
        %           cell array of strings with model names for particular
        %           set of models
        %   trainSetShare:  value between 0 and 1. testSet gets share of
        %                   1 - trainSetShare.
        %   nGenAssessFolds: number of folds of generalization assessment cross validation
        %
        function run( obj, models, trainSetShare, nGenAssessFolds )
            curTimeStr = buildCurrentTimeString();
            saveDir = ['Training' curTimeStr];
            mkdir( saveDir );
            cd( saveDir );
            diary( ['IdTrainPipe' curTimeStr '.log'] );
            
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
            obj.trainSet.saveDataFList( ['trainSet' curTimeStr '.flist'] );
            obj.testSet.saveDataFList( ['testSet' curTimeStr '.flist'] );

            for modelName = models
                fprintf( ['\n\n===================================\n',...
                              '##   Training model "%s"\n',...
                              '===================================\n\n'], modelName{1} );
                if nGenAssessFolds > 1
                    fprintf( '\n==  Starting generalization performance assessment CV...\n\n' );
                    obj.generalizationPerfomanceAssessCVtrainer.setNumberOfFolds( nGenAssessFolds );
                    obj.generalizationPerfomanceAssessCVtrainer.setData( obj.trainSet );
                    obj.generalizationPerfomanceAssessCVtrainer.setPositiveClass( modelName{1} );
                    obj.generalizationPerfomanceAssessCVtrainer.verbose = obj.verbose;
                    obj.generalizationPerfomanceAssessCVtrainer.run();
                    genPerfCVresults = obj.generalizationPerfomanceAssessCVtrainer.getPerformance();
                    fprintf( '\n==  Performance after generalization assessment CV:\n' );
                    disp( genPerfCVresults );
                end
                obj.trainer.setData( obj.trainSet, obj.testSet );
                obj.trainer.setPositiveClass( modelName{1} );
                obj.trainer.verbose = obj.verbose;
%                obj.trainer.setMakeProbModel( true );
                fprintf( '\n==  Training final model on trainSet...\n\n' );
                obj.trainer.run();
                fprintf( '\n==  Testing final model on testSet... \n\n' );
                trainPerfresults = obj.trainer.getPerformance();
                fprintf( ['\n\n===================================\n',...
                              '##   "%s" Performance: %f\n',...
                              '===================================\n\n'], ...
                              modelName{1}, trainPerfresults.double() );
                model = obj.trainer.getModel();
                featureCreator = obj.featureCreator;
                save( [modelName{1} buildCurrentTimeString() '.model.mat'], ...
                      'model', 'featureCreator', ...
                      'trainPerfresults' );
            end;
            
            diary off;
            cd( '..' );
        end
        %% ----------------------------------------------------------------
        
        function createTrainTestSplit( obj, trainSetShare )
            [obj.trainSet, obj.testSet] = obj.data.getShare( trainSetShare );
        end
        %% ----------------------------------------------------------------
        

    end
    
    %% --------------------------------------------------------------------
    methods (Access = private)
    end
    
end

