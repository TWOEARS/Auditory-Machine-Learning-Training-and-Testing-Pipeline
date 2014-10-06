classdef IdSimConvRoomWrapper < IdWp1ProcInterface

    %%---------------------------------------------------------------------
    properties (SetAccess = private)
        convRoomSim;
    end
    
    %%---------------------------------------------------------------------
    methods (Static)
    end
    
    %%---------------------------------------------------------------------
    methods (Access = public)
        
        function obj = IdSimConvRoomWrapper()
            obj = obj@IdWp1ProcInterface();
            obj.convRoomSim = simulator.SimulatorConvexRoom();
        end
        
        %%-----------------------------------------------------------------

        function run( obj, idTrainData, className )
            error('implement me');
        end

    end
    
    %%---------------------------------------------------------------------
    methods (Access = private)
    end
    
    
end

