classdef FreesoundOptions < handle
    %FreesoundOptions Bundles download options for the FreesoundDownloader.
    %These options are sent with the download request to Freesound.org and
    %thus affect the resulting sound files.
    %
    %   Options that can be set to get specific results:
    %
    %   Field           Result
    %
    %   maxCount    -   maximum amount of sound files to download, use any
    %                   negative value for all sound files that match
    %                   request
    %
    %   query       -   search term for sound files, e.g. 'street scene'
    %
    %   tags        -   tags that the sound files are tagged with, e.g.
    %                   'traffic', 'car', 'noisy', ...
    %
    %   duration    -   duration of sound files in seconds, 
    %                   this parameter can be a fixed number such as 20
    %                   or a vector with minimum and maximum duration
    %                   such as [0, 20] for sound files with a duration
    %                   between 0 and 20 seconds
    %
    %   sort        -   order in which the resulting sound files of the
    %                   request are sorted:
    %
    %                   score           Sort by a relevance score returned 
    %                                   by our search engine (default).
    %                   
    %                   duration_desc 	Sort by the duration of the sounds, 
    %                                   longest sounds first.
    %                   
    %                   duration_asc 	Same as above, but shortest sounds 
    %                                   first.
    %                   
    %                   created_desc 	Sort by the date of when the sound 
    %                                   was added. newest sounds first.
    %                   
    %                   created_asc 	Same as above, but oldest sounds 
    %                                   first.
    %                   
    %                   downloads_desc 	Sort by the number of downloads, 
    %                                   most downloaded sounds first.
    %                   
    %                   downloads_asc 	Same as above, but least downloaded 
    %                                   sounds first.
    %                   
    %                   rating_desc 	Sort by the average rating given to 
    %                                   the sounds, highest rated first.
    %                   
    %                   rating_asc      Same as above, but lowest rated 
    %                                   sounds first.
    
    properties(SetAccess = protected)
        m_maxCount
        m_query
        m_tags
        m_duration
        m_sort
    end
    
    properties(Constant)
        DEFAULT_MAXCOUNT    = 15;
        DEFAULT_QUERY       = '';
        DEFAULT_TAGS        = {};
        DEFAULT_DURATION    = 20;
        DEFAULT_SORT        = 'rating_desc';
        SORTING_FLAGS       = {'score', 'duration_desc', 'duration_asc', ...
                               'created_desc', 'created_asc', ...
                               'downloads_desc', 'downloads_asc', ... 
                               'rating_desc', 'rating_asc'};
    end
    
    methods
        
        function obj = FreesoundOptions(varargin)
            p = inputParser;
            addParameter(p,'maxCount',obj.SetMaxCount(obj.DEFAULT_MAXCOUNT), @obj.SetMaxCount);
            addParameter(p,'query',obj.SetQuery(obj.DEFAULT_QUERY),@obj.SetQuery);
            addParameter(p,'tags',obj.SetTags(obj.DEFAULT_TAGS),@obj.SetTags);
            addParameter(p,'duration',obj.SetDuration(obj.DEFAULT_DURATION),@obj.SetDuration);
            addParameter(p,'sortFlag',obj.SetSort(obj.DEFAULT_SORT),@obj.SetSort);
            parse(p, varargin{:});                    
            % note, that p.Results is not correct and in sync with the
            % actual obj properties, because the <Set> function returns 
            % <1> as default parameter. However this can be ignored here,  
            % as the class properties are set within the function
        end
        
        function SampleOptions1(obj)
            obj.SetMaxCount(40);
            obj.SetQuery('');
            obj.SetTags({'cat'});
            obj.SetDuration([0 20]);
            obj.SetSort('downloads_desc'); 
        end
                
        function out = SetMaxCount(obj, maxCount)
            out = false;
            assert(isnumeric(maxCount));
            obj.m_maxCount = (maxCount >= 0)*maxCount + (maxCount < 0)*-1;
            out = true;
        end
        
        function out = SetQuery(obj, query)           
            out = false; 
            if isempty(query) 
                obj.m_query = '';
                out = true;
                return;
            end
            
            assert(ischar(query))
            obj.m_query = query;    
            out = true; 
        end
        
        function out = SetTags(obj, tags)            
            out = false;
            if isempty(tags) 
                obj.m_tags = '';
                out = true;
                return;
            end
            
            [m n] = size(tags);
            try
                assert (iscellstr(tags) && m == 1 && n > 0);
            catch tmpExc
                excId = 'FreesoundOptions:InputErr';
                msg = '<tags> has to be a cell array of strings of size [1 n] with n > 0';
                exc = MException(excId, msg);
                exc = exc.addCause(tmpExc);
                throw(exc)
            end 
            prefix(1:size(tags,2)) = {'tag:'};
            obj.m_tags = strjoin(strcat(prefix, tags), ' ');  
            out = true;
        end
        
        function out = SetDuration(obj, duration)
            out = false;
            if isempty(duration) 
                obj.m_duration = '';
                out = true;
                return;
            end
            
            [m n] = size(duration);
            try
                assert(isnumeric(duration) && m == 1 && n > 0 && n < 3);
            catch tmpExc
                excId = 'FreesoundOptions:InputErr';
                msg = '<duration> has to be a number or a vector of size [1 2]';
                exc = MException(excId, msg);
                exc = exc.addCause(tmpExc);
                throw(exc)
            end
            
            if (n == 2)
                min = num2str(duration(1));
                max = num2str(duration(2));
                obj.m_duration = ['[',min,' TO ',max,']'];
            else
                obj.m_duration = strcat('duration:',num2str(duration));
            end
            out = true;
        end
        
        function out = SetSort(obj, sortFlag)
            out = false;
            if isempty(sortFlag) 
                obj.m_sort = '';
                out = true;
                return;
            end
            
            assert( ischar(sortFlag) && ...
                    any( validatestring(sortFlag, obj.SORTING_FLAGS) ) )
                
            obj.m_sort = sortFlag;  
            out = true;
        end    
    end
    
end