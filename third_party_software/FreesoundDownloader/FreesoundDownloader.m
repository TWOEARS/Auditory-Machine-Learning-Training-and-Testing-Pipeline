 classdef FreesoundDownloader
    %FreesoundDownloader Can be used to download sound files from
    %freesound.org
    %   This class uses a python embedding of a script, that wraps the 
    %   freesound.org python client library. 
    %   Note that this class requires Matlab2015 or above.
    %
    %   The use of this class requires a valid API key that is 
    %   assigned to a freesound.org account. 
    %
    %   Use as follows:
    %
    %   downloader = FreesoundDownloader()
    %
    
     properties(Constant)
        m_sKeyIniPath = '/key.ini';
    end
    
    properties(Access = protected)
        m_sKey
    end
    

    
    methods
        
        function obj = FreesoundDownloader()
            key = '';
            if exist(FreesoundDownloader.m_sKeyIniPath, 'file') == 2
                key = fileread(FreesoundDownloader.m_sKeyIniPath);
                key = strsplit(key,'API_KEY=');
                key = strtrim(key{2});
            end
            if isempty(key)
                prompt = 'Please enter your Freesound API key!\n';
                key = input(prompt,'s');
                f = fopen(FreesoundDownloader.m_sKeyIniPath,'w+');
                fprintf(f, 'API_KEY=%s', key);
            end
            obj.m_sKey = key;
            
            
        end
        
        function flist = GetData(obj, varargin)
            p = inputParser;
            defaultOptions = FreesoundOptions();
            
            addParameter(p, 'directory', strcat(pwd, '/data/'), @(x) ischar(x) && exist(x, 'dir'));
            addParameter(p, 'useLocalFiles', false, @(x) islogical(x));
            addParameter(p,'options',defaultOptions,@(x) isa(x, 'FreesoundOptions'));
            parse(p, varargin{:});

            fsOptions = p.Results.options;
            directory = fileparts(p.Results.directory);
            useLocalFiles = p.Results.useLocalFiles;
            if ~useLocalFiles     
                if ~isempty(obj.m_sKey)
                    fprintf('FreesoundDownloader:\tSTART FREESOUND DOWNLOADER\n\t\t\t\t\t\tThis may take a while, get yourself a coffee...\n');
                    py.script_FreesoundDownloader.getFreesoundData( ...
                                                obj.m_sKey, ...
                                                directory, ...
                                                fsOptions.m_maxCount, ...
                                                fsOptions.m_query, ...
                                                fsOptions.m_tags, ...
                                                fsOptions.m_duration, ...
                                                fsOptions.m_sort);
                else
                    disp('No API key found! Call <FreesoundDownloader()> to enter API key or delete <key.ini>.')
                end
            end
            flist = obj.CreateFileList(directory);
        end
        
    end
    
    methods(Access = protected)
        function out = CreateFileList(obj, directory)
            assert(ischar(directory) && exist(directory, 'dir'))
            
            files = dir(strcat(directory,'/*.mp3'));
            fnames = strcat(strcat(directory,'/'),{files(:).name});
                        
            flistname = strcat(directory, '/data.flist'); 
            flist = fopen(flistname, 'w+');
            fprintf(flist, '%s\n', fnames{:});
            fclose(flist);
            
            out = flistname;
        end
    
    end
    
    
end

