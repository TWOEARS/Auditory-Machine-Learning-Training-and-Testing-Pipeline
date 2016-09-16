classdef CaffeModel < Models.Base
    % PREREQUISITE:
    % caffe library path (directory containing libcaffe.so must be added to
    % the LD_LIBRARY_PATH environment variable prior to launching MATLAB)
    %% --------------------------------------------------------------------
    properties (SetAccess = ?ModelTrainers.CaffeModel)
        fpath_net_def;
        fpath_weights;
        thr;            % output node thresholds, default is 0.5
        has_thr;
    end
    
    properties (SetAccess = ?ModelTrainers.CaffeModel, Transient=true)
        net;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = CaffeModel(dir_matcaffe, ...
                modelDir, fname_net_def, fname_weights, ...
                thr)
           % Add caffe/matlab to our Matlab search PATH to use matcaffe
            if exist([dir_matcaffe, filesep, '+caffe'], 'dir')
                addpath(dir_matcaffe);
            else
                error('Could not find matcaffe.');
            end
            obj.net = [];
            obj.initNet(modelDir, fname_net_def, fname_weights);
            if exist('thr', 'var') && ~isempty(thr)
                obj.thr = thr;
                if ~isa(obj.thr, 'cell')
                    obj.thr = {obj.thr};
                end
                obj.has_thr = true;
            else
                obj.has_thr = false;
            end
        end
        %% -----------------------------------------------------------------
        

        %% -----------------------------------------------------------------
        function initNet(obj, modelDir, fname_net_def, fname_weights)
            % INITNET
            % innitialize underlying caffe network object from definition
            % and weight files
            %% --------------------------------------------------------------------
            
%             if ~exist(modelDir, 'dir')
%                 error('Could not find model directory %s.', modelDir);
%             end
%             if ~exist(fullfile(modelDir, fname_net_def), 'file')
%                 error('Could not find network definition prototxt.');
%             else
%                 obj.fpath_net_def = fullfile(modelDir, fname_net_def);
%             end
%             if ~exist(fullfile(modelDir, fname_weights), 'file')
%                 error('Could not find network weights file.');
%             else
%                 obj.fpath_weights = fullfile(modelDir, fname_weights);
%             end

            obj.fpath_net_def = xml.dbGetFile(fullfile(modelDir, fname_net_def));
            obj.fpath_weights = xml.dbGetFile(fullfile(modelDir, fname_weights));
            
            phase = 'test'; % run with phase test (so that dropout isn't applied)
            if ~isempty(obj.net)
                delete(obj.net);
                clear obj.net;
            end
            obj.net = caffe.Net(obj.fpath_net_def, obj.fpath_weights, phase);
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods(Access = protected)
        
        function [y,score] = applyModelMasked( obj, x )
            blobs_in = x{1};
            blobs_in_names = x{2};
            data_in = cell(numel(obj.net.inputs));
            % prepare input data by selecting required features
            for ii = 1:numel(obj.net.inputs)
                for jj = 1:numel(blobs_in_names)
                    if strcmp(blobs_in_names{jj}, obj.net.inputs{ii})
                        data_in{ii} = blobs_in{jj};
                    end
                end
            end
            blobs_out = obj.net.forward(data_in);
            % extract predictions from network
            score = {};
            y = {};
            for ii = 1:numel(obj.net.outputs)
                score.(obj.net.outputs{ii}) = double(blobs_out{ii});
                d = blobs_out{ii};
                if obj.has_thr
                    thr_tmp = obj.thr{ii};
                else
                    thr_tmp = 0.5;
                end
                d(d >= thr_tmp) = 1;
                d(d < thr_tmp) = -1;
                y.(obj.net.outputs{ii}) = d;
            end
        end
        %% -----------------------------------------------------------------

        function delete(obj)
            % DELETE Destructor
            
            % Shut down the network
            delete(obj.net);
            clear obj.net;
        end
        
    end
    
    methods (Static)

        function setMode(use_gpu, gpu_id)
            % Set caffe mode (gpu or cpu mode)
            if exist('use_gpu', 'var') && use_gpu
                caffe.set_mode_gpu();
                if ~exist('gpu_id', 'var')
                    gpu_id = 0;  % we will use the first gpu in this demo
                end
                caffe.set_device(gpu_id);
                verboseFprintf( obj, 'Using caffe in GPU mode, device id:%d.\n', gpu_id );
            else
                caffe.set_mode_cpu();
                verboseFprintf( obj, 'Using caffe in CPU mode.\n' );
            end
        end
        %% -----------------------------------------------------------------

    end
    
end

