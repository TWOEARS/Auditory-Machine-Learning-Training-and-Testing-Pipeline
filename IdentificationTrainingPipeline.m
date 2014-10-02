classdef IdentificationTrainingPipeline < handle

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        trainer;
        wp1proc;
        wp2proc;
        featureProc;
        wavNames;
        classesInWavList;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdentificationTrainingPipeline()
        end
        
        %%-----------------------------------------------------------------
        function addModelCreator( obj, trainer )
            if ~isa( trainer, 'IdTrainerInterface' )
                error( 'ModelCreator must be of type IdTrainerInterface.' );
            end
            obj.trainer = trainer;
        end
        
        function setWp1Processor( obj, wp1proc )
            if ~isa( wp1proc, 'IdWp1ProcInterface' )
                error( 'Wp1Processor must be of type IdWp1ProcInterface.' );
            end
            obj.wp1proc = wp1proc;
        end
        
        function setWp2Processor( obj, wp2proc )
            if ~isa( wp2proc, 'IdWp2ProcInterface' )
                error( 'Wp2Processor must be of type IdWp2ProcInterface.' );
            end
            obj.wp2proc = wp2proc;
        end
        
        function setFeatureProcessor( obj, featureProc )
            if ~isa( featureProc, 'IdFeatureProcInterface' )
                error( 'FeatureProcessor must be of type IdFeatureProcInterface.' );
            end
            obj.featureProc = featureProc;
        end
        
        %%-----------------------------------------------------------------
        function setWavFileList( obj, wavflist )
            if ~isa( wavflist, 'char' )
                error( 'wavflist must be a string.' );
            end
            if ~exist( wavflist, 'file' )
                error( 'Wavflist not found.' );
            end
            fid = fopen( wavflist );
            wavs = textscan( fid, '%s' );
            for k = 1:length(wavs{1})
                wavName = wavs{1}{k};
                if ~exist( wavName, 'file' )
                    error ( 'Could not find %s listed in %s.', wavName, wavflist );
                end
                wavClass = IdEvalFrame.readEventClass( wavName );
                obj.classesInWavList = ...
                    unique( [obj.classesInWavList, wavClass] );
            end
            fclose( fid );
            obj.wavNames = wavs{1}; 
        end
        
        %%-----------------------------------------------------------------
        function run( obj, models )
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
end

