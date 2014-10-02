classdef IdentificationTrainingPipeline < handle

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        trainer;
        wp1proc;
        wp2proc;
        featureProc;
        wavflist;
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
        end
        
        function setWp1Processor( obj, wp1proc )
            if ~isa( wp1proc, 'IdWp1ProcInterface' )
                error( 'Wp1Processor must be of type IdWp1ProcInterface.' );
            end
        end
        
        function setWp2Processor( obj, wp2proc )
            if ~isa( wp2proc, 'IdWp2ProcInterface' )
                error( 'Wp2Processor must be of type IdWp2ProcInterface.' );
            end
        end
        
        function setFeatureProcessor( obj, featureProc )
            if ~isa( featureProc, 'IdFeatureProcInterface' )
                error( 'FeatureProcessor must be of type IdFeatureProcInterface.' );
            end
        end
        
        %%-----------------------------------------------------------------
        function setWavFileList( obj, wavflist )
            if ~isa( wavflist, 'char' )
                error( 'wavflist must be a string.' );
            end
        end
        
        %%-----------------------------------------------------------------
        function run( obj, models )
        end
        
    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
end

