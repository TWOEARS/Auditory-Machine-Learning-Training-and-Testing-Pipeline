classdef IdentTrainPipeData < handle
   
    properties (SetAccess = private)%{?IdentificationTrainingPipeline, ?IdTrainerInterface, ?IdWp1ProcInterface, ?IdWp2ProcInterface, ?IdFeatureProcInterface})
        classNames;
        data;
        emptyDataStruct;
    end
    
    methods
        
        %% Constructor.
        function obj = IdentTrainPipeData()
            obj.emptyDataStruct = struct( 'files', IdentTrainPipeDataElem.empty );
            obj.data = obj.emptyDataStruct;
        end
        
        %% easy get interface
        function varargout = subsref( obj, S )
            if strcmp(S(1).type,'.')
                mc = metaclass( obj );
                pr = mc.PropertyList(strcmp({mc.PropertyList.Name},S(1).subs));
                if ~isempty( pr )
                    pgaccess = pr.GetAccess;
                    if strcmpi( pgaccess, 'private' ), error( 'private property' ); end;
                end
                me = mc.MethodList(strcmp({mc.MethodList.Name},S(1).subs));
                if ~isempty( me )
                    maccess = me.Access;
                    if strcmpi( maccess, 'private' ), error( 'private property' ); end;
                end
            end
            if (length(S) == 1) && strcmp(S(1).type,'()')
                classes = S.subs{1,1};
                if isa( classes, 'char' )
                    if classes == ':'
                        cIdx = 1:length( obj.data );
                    else
                        cIdx = obj.getClassIdx( classes ); 
                    end;
                elseif isa( classes, 'cell' )
                    cIdx = [];
                    for c = classes
                        cIdx(end+1) = obj.getClassIdx( c{1} );
                    end
                end
                if size( S.subs, 2 ) > 1
                    fIdx = S.subs{1,2};
                else
                    fIdx = ':';
                end
                if size( S.subs, 2 ) > 2
                    dIdx = S.subs{1,3};
                    if (strcmp( dIdx, 'x' ) || strcmp( dIdx, 'y' )) ...
                            && size( S.subs, 2 ) > 3
                        if length(cIdx) > 1 || length(fIdx) > 1
                            error( 'Indexes for x or y can only be chosen for one class and one file.' );
                        end
                        xIdx = S.subs{1,4};
                        varargout{1:nargout} = obj.data(cIdx).files(fIdx).(dIdx)(xIdx);
                    else
                        out = {obj.data(cIdx(1)).files(fIdx).(dIdx)};
                        for c = cIdx(2:end)
                            out = [out, {obj.data(c).files(fIdx).(dIdx)}];
                        end
                        varargout{1:nargout} = out';
                    end
                else
                    out = obj.data(cIdx(1)).files(fIdx);
                    for c = cIdx(2:end)
                        out = [out; obj.data(c).files(fIdx)];
                    end
                    varargout{1:nargout} = out;
                end
            else
                if nargout == 0
                    builtin( 'subsref', obj, S );
                else
                    varargout{1:nargout} = builtin( 'subsref', obj, S );
                end
            end
        end
        
        %% easy set interface
        function obj = subsasgn( obj, S, val )
            if (length(S) == 1) && strcmp(S(1).type,'()')
                className = S.subs{1,1};
                if isa( className, 'char' )
                    cIdx = obj.getClassIdx( className, 'createIfnExst' );
                else
                    error( 'className needs to be a string' );
                end
                if size( S.subs, 2 ) > 1
                    fIdx = S.subs{1,2};
                else
                    error( 'file index must be set for assignment' );
                end
                if isa( fIdx, 'char' ) 
                    if strcmp( fIdx, '+' )
                        fIdx = length( obj.data(cIdx).files ) + 1;
                    else
                        error( 'unknown indexing' );
                    end
                end
                if size( S.subs, 2 ) > 2
                    dIdx = S.subs{1,3};
                else
                    dIdx = 'wavFileName';
                end
                if (strcmp( dIdx, 'x' ) || strcmp( dIdx, 'y' )) ...
                    && size( S.subs, 2 ) > 3
                    xIdx = S.subs{1,4};
                    if isa( xIdx, 'char' )
                        dIdxLen = length( obj.data(cIdx).files(fIdx).(dIdx) );
                        switch xIdx
                            case ':'
                                xIdx = 1:dIdxLen;
                            case '+'
                                xIdx = dIdxLen+1:dIdxLen+1+size(val,1);
                            otherwise
                                error( 'unknown indexing' );
                        end
                    end
                    obj.data(cIdx).files(fIdx).(dIdx)(xIdx,:,:,:,:,:,:) = val;
                else
                    obj.data(cIdx).files(fIdx).(dIdx) = val;
                end
            else
                obj = builtin( 'subsasgn', obj, S, val );
            end
        end
        
%         function l = length( obj )
%             l = max( 0, obj.cbuf.lst - obj.cbuf.fst + 1 );
%         end
%             
%         function s = size( obj )
%             s = size(obj.cbuf.dat);
%             s(1) = length( obj );
%         end
%         
%         function n = numel( obj )
%             n = prod( size( obj ) );
%         end
        
        function ind = end( obj, k, n )
            switch k
                case 1
                    ind = length( obj.data );
                case 2
                    error( 'dont know how to implement this yet' );
                case 3
                    error( 'dont know how to implement this yet' );
                case 4
                    error( 'dont know how to implement this yet' );
            end
        end
        
%         function ie = isempty( obj )
%             ie = (obj.cbuf.lst < obj.cbuf.fst);
%         end
        
    end
    
    methods (Access = private)

        %% function cIdx = getClassIdx( obj, className, mode )
        %       returns the index of the class with name 'className'
        %       if mode is 'createIfnExst', the class will be created in
        %       the data structure if it does not exist yet.
        function cIdx = getClassIdx( obj, className, mode )
            [classAlreadyPresent,cIdx] = max( strcmp( obj.classNames, className ) );
            if isempty( classAlreadyPresent ) || ~classAlreadyPresent
                if nargin < 3, mode = ''; end;
                if strcmpi( mode, 'createIfnExst' )
                    obj.classNames{end+1} = className;
                    cIdx = length( obj.classNames );
                    obj.data(cIdx) = obj.emptyDataStruct;
                else
                    cIdx = [];
                end
            end
        end
    
    end
end