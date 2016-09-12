classdef CaffeModel < Models.Base
    % PREREQUISITE:
    % caffe library path (directory containing libcaffe.so must be added to
    % the LD_LIBRARY_PATH environment variable prior to launching MATLAB)
    %% --------------------------------------------------------------------
    properties (SetAccess = ?ModelTrainers.CaffeModel)
        net;
    end
    
    %% --------------------------------------------------------------------
    methods

        function obj = CaffeModel(dir_matcaffe, ...
                fpath_net_def, fpath_weights, use_gpu)
           % Add caffe/matlab to our Matlab search PATH to use matcaffe
            if exist([dir_matcaffe, filesep, '+caffe'], 'dir')
                addpath(dir_matcaffe);
            else
                error('Could not find matcaffe.');
            end
            if ~exist(fpath_net_def, 'file')
                error('Could not find network definition prototxt.');
            end
            if ~exist(fpath_weights, 'file')
                error('Could not find network weights file.');
            end
            % Set caffe mode
            if exist('use_gpu', 'var') && use_gpu
                caffe.set_mode_gpu();
                gpu_id = 0;  % we will use the first gpu in this demo
                caffe.set_device(gpu_id);
                verboseFprintf( obj, 'Using caffe in GPU mode, device id:%d.\n', gpu_id );
            else
                caffe.set_mode_cpu();
                verboseFprintf( obj, 'Using caffe in CPU mode.\n' );
            end
            % Initialize a network
            phase = 'test'; % run with phase test (so that dropout isn't applied)
            obj.net = caffe.Net(fpath_net_def, fpath_weights, phase);  
        end
        %% -----------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods(Access = protected)
        
        function [y,score] = applyModelMasked( obj, x )
            blobs_in = x{1};
            blobs_in_names = x{2};
            %blobs_in_idx = cellfun(@(v) find(strcmp(v, {'ratemap','amsFeatures'})),{'amsFeatures', 'ratemap'}, 'un', false)
            data_in = cell(numel(obj.net.inputs));
            for ii = 1:numel(obj.net.inputs)
                for jj = 1:numel(blobs_in_names)
                    if strcmp(blobs_in_names{jj}, obj.net.inputs{ii})
                        data_in{ii} = blobs_in{jj};
                    end
                end
            end
            scores = obj.net.forward(data_in);
            score = squeeze(scores);
            y = 0;
        end
        %% -----------------------------------------------------------------

    end
    
    methods (Static)

        %% -------------------------------------------------------------------------------
        function x_new = prepare_input( x )
            % format: W x H x C with BGR channels
            x_new = x(:, :, [3, 2, 1]);  % permute channels from RGB to BGR
            x_new = permute(x_new, [2, 1, 3]);  % flip width and height
        end
    end
    
end

