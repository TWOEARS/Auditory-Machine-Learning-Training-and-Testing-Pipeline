function reducedFile = ReduceFileList(originalFile, portion)
% ReduceFileList(file, portion) 
    %   This function takes a file list <file> with sound files of  
    %   different classes and returns a new reduced file list with the same    
    %   file name as the original file plus add-on '_reduced', whereas 
    %   the amount of files is reduced to the specified <portion> of files 
    %   per sound class. Note that the reduced file overwrites files with 
    %   the same name.
    %
    %   The parameter <portion> does not refer to the total amount of
    %   files, but the amount of files per class, which is defined by the
    %   directory, the sound file is contained in. As well if the portion
    %   of a class is not a whole number, it is rounded to the smaller one.  
    %   
    %   Example: If the original file has 10 sound files of class 'alarm',
    %   the reduced one will have only 3 sound files of class 'alarm' if
    %   <portion> = 0.3. The same applies if <portion> = 0.3999 due to
    %   rounding to the smaller whole number.
    %% --------------------------------------------------------------------
    
    % check for valid parameters
    if ~(ischar(originalFile) && exist(originalFile, 'file') && ...
            strcmp(originalFile(end-5:end),'.flist'))
        error(['The 1st parameter <originalFile> has to be a string ' ...
            'and reference to a valid .flist file']);
    end
    if ~(isfloat(portion) && length(portion) == 1 && 0 < portion && ...
        portion <= 1)
        error(['The 2nd parameter <portion> has to be a single float ' ...
            'greater than 0 and less or equal than 1']);
    end    
    
    splitted = strsplit(originalFile, '.');
    reducedFile = strcat(strjoin(splitted(1:end-1), '.'), '_reduced.flist');
           
    data = strrep(textread(originalFile, '%s'), '\', '/');
    splitted = regexp(data, '/', 'split');
    totalClasses = cellfun(@(x) x{3}, splitted, 'UniformOutput', false);
    classes = unique(totalClasses);
    
    flist = fopen(reducedFile, 'w+');
    for i=1:length(classes)
        idx = find(ismember(totalClasses, classes{i})); 
        limit = floor( length(idx)*portion );
            fprintf(flist, '%s\n', data{idx(1:limit)} );
    end
    fclose(flist);
    
    
    