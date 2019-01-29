classdef BAC_BAextended < PerformanceMeasures.Base
    
    %% --------------------------------------------------------------------
    properties (SetAccess = protected)
        tp;
        fp;
        tn;
        fn;
        sensitivity;
        specificity;
        acc;
        resc_b;
        resc_t;
        resc_t2;
    end
    
    %% --------------------------------------------------------------------
    methods
        
        function obj = BAC_BAextended( yTrue, yPred, varargin )
            obj = obj@PerformanceMeasures.Base( yTrue, yPred, varargin{:} );
        end
        % -----------------------------------------------------------------

        function po = strapOffDpi( obj )
            po = strapOffDpi@PerformanceMeasures.Base( obj );
            po.resc_b = [];
            po.resc_t = [];
            po.resc_t2 = [];
        end
        % -----------------------------------------------------------------
    
        function b = eqPm( obj, otherPm )
            b = obj.performance == otherPm.performance;
        end
        % -----------------------------------------------------------------
    
        function b = gtPm( obj, otherPm )
            b = obj.performance > otherPm.performance;
        end
        % -----------------------------------------------------------------
    
        function d = double( obj )
            for ii = 1 : size( obj, 2 )
                d(ii) = double( obj(ii).performance );
            end
        end
        % -----------------------------------------------------------------
    
        function s = char( obj )
            if numel( obj ) > 1
                warning( 'only returning first object''s performance' );
            end
            s = num2str( obj(1).performance );
        end
        % -----------------------------------------------------------------
    
        function [obj, performance, dpi] = calcPerformance( obj, yTrue, yPred, ~, dpi, testSetIdData )
            dpi.yTrue = yTrue;
            dpi.yPred = yPred;
            tps = yTrue == 1 & yPred > 0;
            tns = yTrue == -1 & yPred < 0;
            fps = yTrue == -1 & yPred > 0;
            fns = yTrue == 1 & yPred < 0;
            obj.tp = sum( tps );
            obj.tn = sum( tns );
            obj.fp = sum( fps );
            obj.fn = sum( fns );
            tp_fn = sum( yTrue == 1 );
            tn_fp = sum( yTrue == -1 );
            if tp_fn == 0
                warning( 'No positive true label.' );
                obj.sensitivity = nan;
            else
                obj.sensitivity = obj.tp / tp_fn;
            end
            if tn_fp == 0
                warning( 'No negative true label.' );
                obj.specificity = nan;
            else
                obj.specificity = obj.tn / tn_fp;
            end
            obj.acc = (obj.tp + obj.tn) / (tp_fn + tn_fp); 
            performance = 0.5 * obj.sensitivity + 0.5 * obj.specificity;
            obj = obj.analyzeBAextended( yTrue, yPred, testSetIdData, dpi.sampleIds );
        end
        % -----------------------------------------------------------------

        function obj = analyzeBAextended( obj, yTrue, yPred, testSetIdData, sampleIds )
            fprintf( 'analyzing BA-extended' );
            obj.resc_b = RescSparse( 'uint32', 'uint8' );
            obj.resc_t = RescSparse( 'uint32', 'uint8' );
            obj.resc_t2 = RescSparse( 'uint32', 'uint8' );
            bapis = cell( numel( testSetIdData.data ), 1 );
            agBapis = cell( numel( testSetIdData.data ), 1 );
            asgns = cell( numel( testSetIdData.data ), 1 );
            agAsgns = cell( numel( testSetIdData.data ), 1 );
            agBapis2 = cell( numel( testSetIdData.data ), 1 );
            agAsgns2 = cell( numel( testSetIdData.data ), 1 );
            blockAnnotsCacheFiles = testSetIdData(:,'blockAnnotsCacheFile');
            [bacfClassIdxs,bacfci_ic] = PerformanceMeasures.BAC_BAextended.getFileIds( blockAnnotsCacheFiles );
            sampleFileIdxs_all = testSetIdData(:,'pointwiseFileIdxs');
            sampleFileIdxs = sampleFileIdxs_all(sampleIds);
            for ii = 1 : numel( testSetIdData.data )
                scp.classIdx = nan;
                scp.fileClassId = bacfClassIdxs(ii);
                scp.fileId = sum( bacfci_ic(1:ii) == bacfci_ic(ii) );
                blockAnnotations_ii = testSetIdData(ii,'blockAnnotations');
                sampleIds_ii = sampleIds(sampleFileIdxs==ii);
                sampleIds_ii = sampleIds_ii - sum( sampleFileIdxs_all <= ii-1 );
                blockAnnotations_ii = blockAnnotations_ii(sampleIds_ii);
                yt_ii = yTrue(sampleFileIdxs==ii,:);
                yp_ii = yPred(sampleFileIdxs==ii,:);
                bacfIdxs_ii = testSetIdData(ii,'bacfIdxs');
                bacfIdxs_ii = bacfIdxs_ii(sampleIds_ii);
                for jj = 1 : numel( blockAnnotsCacheFiles{ii} )
                    scp.id = jj;
                    blockAnnotations = blockAnnotations_ii(bacfIdxs_ii==jj);
                    yt = yt_ii(bacfIdxs_ii==jj);
                    yp = yp_ii(bacfIdxs_ii==jj);
                    if isempty( blockAnnotations ), continue; end
                    [bapis{ii,jj},agBapis{ii,jj},agBapis2{ii,jj},...
                     asgns{ii,jj},agAsgns{ii,jj},agAsgns2{ii,jj}] = ...
                                 PerformanceMeasures.BAC_BAextended.produceBapisAsgns( ...
                                      yt, yp, blockAnnotations,...
                                      scp ); %#ok<*PROPLC>
                end
            end
            asgns = PerformanceMeasures.BAC_BAextended.catAsgns( asgns );
            obj.resc_b = PerformanceMeasures.BAC_BAextended.addDpiToResc( obj.resc_b, asgns, cat( 1, bapis{:} ) );
            fprintf( ':' );
            if any( ~cellfun( @isempty, agAsgns ) )
                agAsgns = PerformanceMeasures.BAC_BAextended.catAsgns( agAsgns );
                obj.resc_t = PerformanceMeasures.BAC_BAextended.addDpiToResc( obj.resc_t, agAsgns, cat( 1, agBapis{:} ) );
            end
%             fprintf( ':' );
%             if any( ~cellfun( @isempty, agAsgns2 ) )
%                 agAsgns2 = PerformanceMeasures.BAC_BAextended.catAsgns( agAsgns2 );
%                 obj.resc_t2 = PerformanceMeasures.BAC_BAextended.addDpiToResc( obj.resc_t2, agAsgns2, cat( 1, agBapis2{:} ) );
%             end
            fprintf( ';' );
            fprintf( '\n' );
        end
        % -----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Static)
        
        function asgns = catAsgns( asgns )
            asgns = cat( 1, asgns{:} );
            asgns = {cat( 1, asgns{:,1} ), cat( 1, asgns{:,2} ), ...
                     cat( 1, asgns{:,3} ), cat( 1, asgns{:,4} )};
        end
        % -----------------------------------------------------------------
        
        function nrs = nanRescStruct()
            
            sdef = {'classIdx',nan,...
                'nAct',nan,...
                'nYp',nan,...
                ...%         'curSnr',nan,...
                ...%         'curSnr_db',nan,...
                'curSnr2',nan,...
                ...%        'dist2bisector',nan,...
                'azmErr',nan,...
                'azmErr2',nan,...
                'azmErr3',nan,...
                ...%        'nStream',nan,...
                ...%        'nAct_segStream',nan,...
                ...%        'curNrj',nan, ...
                ...%        'curNrj_db',nan, ...
                ...%        'curNrjOthers',nan, ...
                ...%        'curNrjOthers_db',nan, ...
                'scpId', nan,...
                'scpIdExt', nan,...
                'fileId', nan,...
                'fileClassId', nan,...
                'blockClass', nan,...
                'gtAzm',nan,...
                'estAzm',nan,...
                'posPresent',nan,...
                ...%        'posSnr',nan,...
                };
            nrs = struct( sdef{:} );
            
        end
        % -----------------------------------------------------------------
        function [bacfClassIdxs,bacfci_ic] = getFileIds( blockAnnotsCacheFiles )
            bacfiles = cellfun( @(x)(applyIfNempty(x,@(c)(c{1}))), blockAnnotsCacheFiles, 'UniformOutput', false )';
            [~,bacfiles] = cellfun( @(x)(applyIfNempty(x,@fileparts)), bacfiles, 'UniformOutput', false );
            [~,bacfClasses] = cellfun( @(c)( strtok(c,'.') ), bacfiles, 'UniformOutput', false );
            [bacfClasses,~] = cellfun( @(c)( strtok(c,'.') ), bacfClasses, 'UniformOutput', false );
            niClasses = {{'alarm'},{'baby'},{'femaleSpeech'},{'fire'},{'crash'},{'dog'},...
                {'engine'},{'footsteps'},{'knock'},{'phone'},{'piano'},...
                {'maleSpeech'},{'femaleScream','maleScream'},{'general'}};
            bacfClassIdxs = cellfun( ...
                @(x)( find( cellfun( @(c)(any( strcmpi( x, c ) )), niClasses ) ) ), ...
                bacfClasses, 'UniformOutput', false );
            bacfClassIdxs(cellfun(@isempty,bacfClassIdxs)) = {nan};
            bacfClassIdxs = cell2mat( bacfClassIdxs );
            [~,~,bacfci_ic] = unique( bacfClassIdxs );
        end
        % -----------------------------------------------------------------
        
        function [pis,agPis,agPis2,asg,agAsg,agAsg2] = produceBapisAsgns( ...
                                                           yt, yp, blockAnnotations, scp )
            [blockAnnotations, yt, yp, sameTimeIdxs] = PerformanceMeasures.BAC_BAextended.findSameTimeBlocks( blockAnnotations, yt, yp );
            [bap, asg] = PerformanceMeasures.BAC_BAextended.extractBAparams( blockAnnotations, scp, yp, yt );
            fprintf( '.' );
            if isfield( blockAnnotations, 'estAzm' ) % is segId
                usti = unique( sameTimeIdxs )';
                agBap = bap;
                agBap(numel( usti )+1:end,:) = [];
                agBap(:,2:10) = deal( PerformanceMeasures.BAC_BAextended.nanRescStruct );
                agYt = yt;
                agYt(numel( usti )+1:end,:) = [];
                agYp = yp;
                agYp(numel( usti )+1:end,:) = [];
                maxc = 0;
                for bb = 1 : numel( usti )
                    stibb = sameTimeIdxs==usti(bb);
                    sumStibb = sum( stibb );
                    maxc = max( maxc, sumStibb );
                    agBap(bb,1:sumStibb) = bap(stibb);
                    agYt(bb,1:sumStibb) = yt(stibb);
                    agYp(bb,1:sumStibb) = yp(stibb);
                end
                agBap(:,maxc+1:end) = [];
                [agBap3, asg, azmErrs] = PerformanceMeasures.BAC_BAextended.aggregateBlockAnnotations3( agBap, agYp, agYt );
%                 [agBap2, agAsg2] = PerformanceMeasures.BAC_BAextended.aggregateBlockAnnotations2( agBap, agYp, agYt );
                agAsg2 = [];
                [agBap, agAsg] = PerformanceMeasures.BAC_BAextended.aggregateBlockAnnotations( agBap, agYp, agYt, azmErrs );
                agPis = PerformanceMeasures.BAC_BAextended.baParams2bapIdxs( agBap );
%                 agPis2 = PerformanceMeasures.BAC_BAextended.baParams2bapIdxs( agBap2 );
                agPis2 = [];
                pis = PerformanceMeasures.BAC_BAextended.baParams2bapIdxs( agBap3 );
                fprintf( ',' );
            else
                pis = PerformanceMeasures.BAC_BAextended.baParams2bapIdxs( bap );
                agPis = [];
                agPis2 = [];
                agAsg = [];
                agAsg2 = [];
            end
        end
        % -----------------------------------------------------------------
        
        function [blockAnnotations,yt,yp,sameTimeIdxs] = findSameTimeBlocks( blockAnnotations,yt,yp )
            
            [~,~,sameTimeIdxs] = unique( [blockAnnotations.blockOffset] );
            for bb = 1 : max( sameTimeIdxs )
                [blockAnnotations(sameTimeIdxs==bb).allGtAzms] = deal( [blockAnnotations(sameTimeIdxs==bb).srcAzms] );
            end
            
        end
        % -----------------------------------------------------------------
        function [baParams, asgn] = extractBAparams( blockAnnotations, scp, yp, yt )
            
            asgn{1} = ((yp == yt) & (yp > 0));
            asgn{2} = ((yp == yt) & (yp < 0));
            asgn{3} = ((yp ~= yt) & (yp > 0));
            asgn{4} = ((yp ~= yt) & (yp < 0));
            
            emptyBap = PerformanceMeasures.BAC_BAextended.nanRescStruct;
            emptyBap.scpId = scp.id;
            emptyBap.fileId = scp.fileId;
            emptyBap.fileClassId = scp.fileClassId;
            emptyBap.classIdx = scp.classIdx;
            baParams = repmat( emptyBap, numel(yt), 1);
            isSegId = isfield( blockAnnotations, 'estAzm' );
            
            baNsa = [blockAnnotations.nActivePointSrcs]';
            tmp = num2cell( baNsa );
            [baParams.nAct] = tmp{:};
            baPp = [blockAnnotations.posPresent]';
            tmp = num2cell( baPp );
            [baParams.posPresent] = tmp{:};
            
            % if sum( baPp ) > 0
            %     baPs = cat( 1, blockAnnotations.posSnr );
            %     tmp = num2cell( min( max(  baPs, -35 ), 35 ) );
            %     [baParams(logical(baPp)).posSnr] = tmp{:};
            % end
            
            baSrcSnr2 = {blockAnnotations.srcSNR2}';
            baSrcAzms = {blockAnnotations.srcAzms}';
            % baSrcSnr = {blockAnnotations.srcSNRactive}';
            % baSrcSnr_db = {blockAnnotations.srcSNR_db}';
            % baSrcNrj = {blockAnnotations.nrj}';
            % baSrcNrj_db = {blockAnnotations.nrj_db}';
            % baSrcNrjOthers = {blockAnnotations.nrjOthers}';
            % baSrcNrjOthers_db = {blockAnnotations.nrjOthers_db}';
            
            isP = yt > 0;
            nCond = (yt < 0) & (~isSegId | ~cellfun( @isempty, baSrcSnr2 ));
            
            if any( nCond )
                % if is negative, the most dominant src in the stream is selected
                [~,curSnr2NmaxIdx] = cellfun( @(x)(max( x )), baSrcSnr2(nCond), 'UniformOutput', false );
                curSnr2N_ = cellfun( @(x,x2)(x(x2)), baSrcSnr2(nCond), curSnr2NmaxIdx );
                curSnr2N = num2cell( min( max( curSnr2N_, -35 ), 35 ) );
                [baParams(nCond).curSnr2] = curSnr2N{:};
                % curNrjoN_ = cellfun( @(x,x2)(x(x2)), baSrcNrjOthers(nCond), curSnr2NmaxIdx );
                % curNrjoN = num2cell( min( max( curNrjoN_, -35 ), 35 ) );
                % [baParams(nCond).curNrjOthers] = curNrjoN{:};
                % curNrjN_ = cellfun( @(x,x2)(x(x2)), baSrcNrj(nCond), curSnr2NmaxIdx );
                % curNrjN = num2cell( min( max( curNrjN_, -35 ), 35 ) );
                % [baParams(nCond).curNrj] = curNrjN{:};
                % curSnrN_ = cellfun( @(x,x2)(x(x2)), baSrcSnr(nCond), curSnr2NmaxIdx );
                % curSnrN = num2cell( min( max( curSnrN_, -35 ), 35 ) );
                % [baParams(nCond).curSnr] = curSnrN{:};
                % curNrjo_dbN_ = cellfun( @(x,x2)(x(x2)), baSrcNrjOthers_db(nCond), curSnr2NmaxIdx );
                % curNrjo_dbN = num2cell( min( max( curNrjo_dbN_, -35 ), 35 ) );
                % [baParams(nCond).curNrjOthers_db] = curNrjo_dbN{:};
                % curNrj_dbN_ = cellfun( @(x,x2)(x(x2)), baSrcNrj_db(nCond), curSnr2NmaxIdx );
                % curNrj_dbN = num2cell( min( max( curNrj_dbN_, -35 ), 35 ) );
                % [baParams(nCond).curNrj_db] = curNrj_dbN{:};
                % curSnr_dbN_ = cellfun( @(x,x2)(x(x2)), baSrcSnr_db(nCond), curSnr2NmaxIdx );
                % curSnr_dbN = num2cell( min( max( curSnr_dbN_, -35 ), 35 ) );
                % [baParams(nCond).curSnr_db] = curSnr_dbN{:};
                curAzmN_ = cellfun( @(x,x2)(x(x2)), baSrcAzms(nCond), curSnr2NmaxIdx );
                curAzmN = num2cell( curAzmN_ );
                [baParams(nCond).gtAzm] = curAzmN{:};
            end
            
            if any( isP )
                % if is positive, the first src in the stream is the positive one, because
                % of the restriction of positives to the first source in a scene config
                % curSnrP_ = cellfun( @(x)(x(1)), baSrcSnr(isP) );
                % curSnrP = num2cell( min( max( curSnrP_, -35 ), 35 ) );
                % [baParams(isP).curSnr] = curSnrP{:};
                % curNrjoP_ = cellfun( @(x)(x(1)), baSrcNrjOthers(isP) );
                % curNrjoP = num2cell( min( max( curNrjoP_, -35 ), 35 ) );
                % [baParams(isP).curNrjOthers] = curNrjoP{:};
                % curNrjP_ = cellfun( @(x)(x(1)), baSrcNrj(isP) );
                % curNrjP = num2cell( min( max( curNrjP_, -35 ), 35 ) );
                % [baParams(isP).curNrj] = curNrjP{:};
                % curSnr_dbP_ = cellfun( @(x)(x(1)), baSrcSnr_db(isP) );
                % curSnr_dbP = num2cell( min( max( curSnr_dbP_, -35 ), 35 ) );
                % [baParams(isP).curSnr_db] = curSnr_dbP{:};
                % curNrjo_dbP_ = cellfun( @(x)(x(1)), baSrcNrjOthers_db(isP) );
                % curNrjo_dbP = num2cell( min( max( curNrjo_dbP_, -35 ), 35 ) );
                % [baParams(isP).curNrjOthers_db] = curNrjo_dbP{:};
                % curNrj_dbP_ = cellfun( @(x)(x(1)), baSrcNrj_db(isP) );
                % curNrj_dbP = num2cell( min( max( curNrj_dbP_, -35 ), 35 ) );
                % [baParams(isP).curNrj_db] = curNrj_dbP{:};
                curSnr2P_ = cellfun( @(x)(x(1)), baSrcSnr2(isP) );
                curSnr2P = num2cell( min( max( curSnr2P_, -35 ), 35 ) );
                [baParams(isP).curSnr2] = curSnr2P{:};
                srcAzmP_ = cellfun( @(x)(x(1)), baSrcAzms(isP) );
                tmp = num2cell( srcAzmP_ );
                [baParams(isP).gtAzm] = tmp{:};
            end
            
            if isSegId
                %     nUsedSpatialStreams = cat( 1, blockAnnotations.nStreams );
                %     tmp = num2cell( nUsedSpatialStreams );
                %     [baParams.nStream] = tmp{:};
                %     tmp = num2cell( min( cellfun( @numel, baSrcAzms ), baNsa ) );
                %     [baParams.nAct_segStream] = tmp{:};
                estAzm = [blockAnnotations.estAzm]';
                tmp = num2cell( estAzm );
                [baParams.estAzm] = tmp{:};
                if any( isP )
                    azmErrP = num2cell( abs( wrapTo180( srcAzmP_ - estAzm(isP) ) ) );
                    [baParams(isP).azmErr] = azmErrP{:};
                end
                if any( nCond )
                    azmErrN = num2cell( abs( wrapTo180( curAzmN_ - estAzm(nCond) ) ) );
                    [baParams(nCond).azmErr] = azmErrN{:};
                end
            end
            
            
            bafiles = cellfun( @(c)(c.srcFile), {blockAnnotations.srcFile}', 'UniformOutput', false );
            nonemptybaf = ~cellfun( @isempty, bafiles );
            bafiles = cellfun( @(x)(x{1}), bafiles(nonemptybaf), 'UniformOutput', false );
            bafFilesepIdxs = cellfun( @(c)( strfind( c, '/' ) ), bafiles, 'UniformOutput', false );
            bafClasses = cellfun( @(fp,idx)(fp(idx(end-1)+1:idx(end)-1)), bafiles, bafFilesepIdxs, 'UniformOutput', false );
            niClassIdxs = struct( 'alarm', 1, 'baby', 2, 'femaleSpeech', 3, 'fire', 4, 'crash', 5, 'dog', 6, ...
                'engine', 7, 'footsteps', 8, 'knock', 9, 'phone', 10, 'piano', 11, ...
                'maleSpeech', 12, 'femaleScream', 13, 'maleScream', 13, 'general', 14 );
            bafClassIdxs = cellfun( @(c)(niClassIdxs.(c)), bafClasses, 'UniformOutput', false );
            
            [baParams(nonemptybaf).blockClass] = bafClassIdxs{:};
            
            
        end
        % -----------------------------------------------------------------
        
        function resc = addDpiToResc( resc, assignments, bapi )
            
            if isempty( bapi ), return; end
            
            ci = zeros( numel( bapi ), 1 );
            for aa = 1:4 % 1: TP, 2: TN, 3: FP, 4: FN
                ci = ci + aa*[assignments{aa}];
            end
            
            bapiFields = fieldnames( bapi );
            bapiFields = [{'counts'}; bapiFields];
            if isfield( resc, 'id' ) && ~isempty( resc.id )
                if numel( bapiFields ) ~= numel( fieldnames( resc.id ) ) || ...
                        ~all( strcmpi( bapiFields, fieldnames( resc.id ) ) )
                    error( 'AMLTTP:apiUsage', 'existing RESC structure differs from BAPI to be added' );
                end
            else
                resc.id(1).counts = 1;
            end
            
            C = zeros( numel( bapi ), numel( bapiFields ) );
            C(:,1) = ci;
            for ii = 2 : numel( bapiFields )
                if isfield( resc.id, bapiFields{ii} )
                    ii_ = resc.id.(bapiFields{ii});
                else
                    ii_ = ii;
                end
                C(:,ii_) = cat( 1, bapi.(bapiFields{ii}) );
                resc.id.(bapiFields{ii}) = ii_;
            end
            
            [C,~,ic] = unique( C, 'rows' );
            paramFactor = accumarray( ic, ones( size( ic ) ) );
            resc = resc.addData( C, paramFactor, true );
            
        end
        % -----------------------------------------------------------------
        
        function [ag, asgn] = aggregateBlockAnnotations( bap, yp, yt, azmErrs )
            
            isyt = yt > 0;
            isyp = yp > 0;
            [ytIdxR,ytIdxC] = find( isyt );
            assert( numel( unique( ytIdxR ) ) == numel( ytIdxR ) ); % because I defined it in my test scripts: target sounds only on src1
            isytR = any( isyt, 2 );
            isypR = any( isyp, 2 );
            ist2tpR = isytR & isypR;
            
            asgn{1} = ist2tpR;
            asgn{2} = ~isypR & ~isytR;
            asgn{3} = isypR & ~isytR;
            asgn{4} = ~isypR & isytR;
            
            ag = bap(:,1);
            % [ag.nAct_segStream] = deal( nan );
            
            
            if any( isytR )
                ytIdxs = sub2ind( size( yt ), ytIdxR, ytIdxC );
                % [ag(isytR).curSnr] = bap(ytIdxs).curSnr;
                % [ag(isytR).curNrj] = bap(ytIdxs).curNrj;
                % [ag(isytR).curNrjOthers] = bap(ytIdxs).curNrjOthers;
                % [ag(isytR).curSnr_db] = bap(ytIdxs).curSnr_db;
                % [ag(isytR).curNrj_db] = bap(ytIdxs).curNrj_db;
                % [ag(isytR).curNrjOthers_db] = bap(ytIdxs).curNrjOthers_db;
                [ag(isytR).curSnr2] = bap(ytIdxs).curSnr2;
                % [ag(isytR).dist2bisector] = bap(ytIdxs).dist2bisector;
                [ag(isytR).blockClass] = bap(ytIdxs).blockClass;
                [ag(isytR).gtAzm] = bap(ytIdxs).gtAzm;
                [ag(isytR).azmErr] = bap(ytIdxs).azmErr;
                if any( ist2tpR )
                    tp_gtAzms = [ag(ist2tpR).gtAzm];
                    assert( all( ~isnan( tp_gtAzms ) ) );
                    tpEstAzms = arrayfun( @(x)(x.estAzm), bap(ist2tpR,:) );
                    azmErrs_tp = tpEstAzms - repmat( tp_gtAzms', 1, size( bap, 2 ) );
                    azmErrs_tp = abs( wrapTo180( azmErrs_tp ) );
                    azmErrs_tp(~isyp(ist2tpR,:)) = nan;
                    tpAzmErrs = num2cell( nanMean( azmErrs_tp, 2 ) );
                    [ag(ist2tpR).azmErr] = tpAzmErrs{:};
                end
            end
            
            if any( ~isytR )
                % tmp = reshape( double( [bap(~isytR,:).curSnr2] ), size( bap(~isytR,:) ) );
                % [~,maxCurSnrIdx] = max( tmp, [], 2 );
                % nIdxs = sub2ind( size( yt ), find( ~isytR ), maxCurSnrIdx );
                % [ag(~isytR).curSnr] = bap(nIdxs).curSnr;
                % [ag(~isytR).curNrj] = bap(nIdxs).curNrj;
                % [ag(~isytR).curNrjOthers] = bap(nIdxs).curNrjOthers;
                % [ag(~isytR).dist2bisector] = bap(nIdxs).dist2bisector;
                [ag(~isytR).blockClass] = deal( nan );
                [ag(~isytR).gtAzm] = deal( nan );
                % tmp = reshape( double( [bap(~isytR,:).curSnr_db] ), size( bap(~isytR,:) ) );
                % [~,maxCurSnrIdx] = max( tmp, [], 2 );
                % nIdxs = sub2ind( size( yt ), find( ~isytR ), maxCurSnrIdx );
                % [ag(~isytR).curSnr_db] = bap(nIdxs).curSnr_db;
                % [ag(~isytR).curNrj_db] = bap(nIdxs).curNrj_db;
                % [ag(~isytR).curNrjOthers_db] = bap(nIdxs).curNrjOthers_db;
                % tmp = reshape( double( [bap(~isytR,:).curSnr2] ), size( bap(~isytR,:) ) );
                % [~,maxCurSnrIdx] = max( tmp, [], 2 );
                % nIdxs = sub2ind( size( yt ), find( ~isytR ), maxCurSnrIdx );
                [ag(~isytR).curSnr2] = deal( nan );
                [ag(~isytR).azmErr] = deal( nan );
                [ag(~isytR).nYp] = deal( 0 );
            end
            
            azmErrs2 = nanMean( azmErrs, 2 );
            azmErrs3 = nanStd( azmErrs, 2 );
            tmp = num2cell( azmErrs2 );
            [ag(:).azmErr2] = tmp{:};
            tmp = num2cell( azmErrs3 );
            [ag(:).azmErr3] = tmp{:};
            tmp = num2cell( sum( yp > 0, 2 ) );
            [ag(:).nYp] = tmp{:};
            [ag(:).estAzm] = deal( nan );
            
        end
        % -----------------------------------------------------------------
        
        function [ag, asgn] = aggregateBlockAnnotations2( bap, yp, yt )
            
            ag = bap;
            validBaps = ~isnan( arrayfun( @(ax)(ax.scpId), bap ) );
            
            isyt = yt > 0;
            isyp = yp > 0;
            [ytIdxR,ytIdxC] = find( isyt );
            assert( numel( unique( ytIdxR ) ) == numel( ytIdxR ) ); % because I defined it in my test scripts: target sounds only on src1
            isytR = any( isyt, 2 );
            isypR = any( isyp, 2 );
            ist2tpR = isytR & isypR;
            t2tpIdxR = find( ist2tpR );
            tpIdxC = ytIdxC(ist2tpR(ytIdxR));
            tpIdx = sub2ind( size( yt ), t2tpIdxR, tpIdxC );
            
            %% compute dist2bisector
            
            % selfIdx = 1 : numel( bap );
            % nonemptyBaps = validBaps & ~isnan( arrayfun( @(ax)(ax.gtAzm), bap ) );
            % selfIdx = selfIdx(nonemptyBaps(selfIdx));
            % if ~isempty( selfIdx )
            %     [selfIdxR,selfIdxC] = ind2sub( size( bap ), selfIdx );
            %     otherIdxs = arrayfun( ...
            %         @(r,c)(sub2ind( size( bap ), repmat( r, 1, size( bap, 2 )-1 ), [1:c-1 c+1:size( bap, 2 )] )), ...
            %         selfIdxR, selfIdxC, 'UniformOutput', false );
            %     otherIdxs = cellfun( @(c)(c(nonemptyBaps(c))), otherIdxs, 'UniformOutput', false );
            
            %     selfGtAzms = wrapTo180( [bap(selfIdx).gtAzm] );
            %     otherGtAzms = cellfun( @(c)(wrapTo180( [bap(c).gtAzm] )), otherIdxs, 'UniformOutput', false );
            %     bisectAzms = cellfun( @(s,o)(wrapTo180(s + wrapTo180( o - s )/2)), num2cell( selfGtAzms ), otherGtAzms, 'UniformOutput', false );
            % mirror to frontal hemisphere
            %     bisectAzms = cellfun( @(c)(sign(c).*abs(abs(abs(c)-90)-90)), bisectAzms, 'UniformOutput', false );
            %     spreads = cellfun( @(s,o)(abs( wrapTo180( o - s ) )), num2cell( selfGtAzms ), otherGtAzms, 'UniformOutput', false );
            %     isSzero = cellfun( @(c)(c == 0), spreads, 'UniformOutput', false );
            %     bisectNormAzms = cellfun( @(b,s)((s - 2*abs( b ))./s), bisectAzms, spreads, 'UniformOutput', false );
            %     bisectNormAzms = cellfun( @(bp,issz)(nansum( [-issz.*ones(1,max(1,numel(bp)));(~issz).*bp], 1 )), ...
            %         bisectNormAzms, isSzero, 'UniformOutput', false );
            %     isBnaNeg = cellfun( @(c)(c < 0), bisectNormAzms, 'UniformOutput', false );
            %     bisectNormAzmsNeg = cellfun( @(b,s)(nansum((abs(b)-s/2)./(90-s/2),1)), ...
            %         bisectAzms, spreads, 'UniformOutput', false );
            %     bisectNormAzms = cellfun( @(bp,bn,isn)(nansum( [-isn.*bn;(~isn).*bp], 1 )), ...
            %         bisectNormAzms, bisectNormAzmsNeg, isBnaNeg, 'UniformOutput', false );
            %     otherSnrs = cellfun( @(c)([bap(c).curSnr]), otherIdxs, 'UniformOutput', false );
            %     otherSnrs = cellfun( @(c)(c - max(c)), otherSnrs, 'UniformOutput', false );
            %     otherSnrNorms = cellfun( @(c)(max(0,1./abs(c-1).^0.2 - 0.4.*abs(c)./100)), otherSnrs, 'UniformOutput', false );
            %     % otherSnrNorms(cellfun(@isempty,otherSnrNorms)) = {1};
            
            %     dist2bisector = cellfun( @(b,s)(double(b)*double(s)'/sum(double(s))), bisectNormAzms, otherSnrNorms, 'UniformOutput', false );
            %     dist2bisector(cellfun(@isempty,dist2bisector)) = {nan};
            %     [ag(selfIdx).dist2bisector] = dist2bisector{:};
            % end
            
            %% assign tp (and following fp,fn,tn) per time instead of per block
            
            istp_ = false( size( ag ) );
            if ~isempty( t2tpIdxR )
                tp_gtAzms = [bap(tpIdx).gtAzm];
                assert( all( ~isnan( tp_gtAzms ) ) );
                azmErrs = arrayfun( @(x)(x.estAzm), bap(t2tpIdxR,:) ) - repmat( tp_gtAzms', 1, size( bap, 2 ) );
                azmErrs = abs( wrapTo180( azmErrs ) );
                azmErrs(~isyp(t2tpIdxR,:)) = nan;
                [tpAzmErr,tpIdxC_] = min( azmErrs, [], 2 );
                tpAzmErr2 = nanMean( azmErrs, 2 );
                tpAzmErr3 = nanStd( azmErrs, 2 );
                tpIdx_ = sub2ind( size( ag ), t2tpIdxR, tpIdxC_ );
                istp_(tpIdx_) = true;
            end
            
            isfp_ = isyp & ~istp_;
            
            isfnR = isytR & ~isypR;
            isfn_ = repmat( isfnR, 1, size( isyt, 2 ) ) & isyt;
            
            istn_ = ~isfn_ & ~isyp & validBaps;
            
            %% assign case-insensitive baParams changes
            
            % [ag.nAct_segStream] = deal( nan );
            acell_nyp = repmat( num2cell( sum( yp > 0, 2 ) ), 1, size( ag, 2 ) );
            [ag(:,:).nYp] = acell_nyp{:};
            
            %% assign case-sensitive baParams changes
            
            if ~isempty( t2tpIdxR )
                acell = num2cell( tpAzmErr );
                [ag(tpIdx_).azmErr] = acell{:};
                acell = num2cell( tpAzmErr2 );
                [ag(tpIdx_).azmErr2] = acell{:};
                acell = num2cell( tpAzmErr3 );
                [ag(tpIdx_).azmErr3] = acell{:};
                %     acell = num2cell( [bap(tpIdx).curSnr] );
                %     a2cell = num2cell( [bap(tpIdx_).curSnr] );
                %     [ag(tpIdx).curSnr] = a2cell{:};
                %     [ag(tpIdx_).curSnr] = acell{:};
                %     acell = num2cell( [bap(tpIdx).curNrj] );
                %     a2cell = num2cell( [bap(tpIdx_).curNrj] );
                %     [ag(tpIdx).curNrj] = a2cell{:};
                %     [ag(tpIdx_).curNrj] = acell{:};
                %     acell = num2cell( [bap(tpIdx).curNrjOthers] );
                %     a2cell = num2cell( [bap(tpIdx_).curNrjOthers] );
                %     [ag(tpIdx).curNrjOthers] = a2cell{:};
                %     [ag(tpIdx_).curNrjOthers] = acell{:};
                %     acell = num2cell( [bap(tpIdx).curSnr_db] );
                %     a2cell = num2cell( [bap(tpIdx_).curSnr_db] );
                %     [ag(tpIdx).curSnr_db] = a2cell{:};
                %     [ag(tpIdx_).curSnr_db] = acell{:};
                %     acell = num2cell( [bap(tpIdx).curNrj_db] );
                %     a2cell = num2cell( [bap(tpIdx_).curNrj_db] );
                %     [ag(tpIdx).curNrj_db] = a2cell{:};
                %     [ag(tpIdx_).curNrj_db] = acell{:};
                %     acell = num2cell( [bap(tpIdx).curNrjOthers_db] );
                %     a2cell = num2cell( [bap(tpIdx_).curNrjOthers_db] );
                %     [ag(tpIdx).curNrjOthers_db] = a2cell{:};
                %     [ag(tpIdx_).curNrjOthers_db] = acell{:};
                acell_curSnr2 = num2cell( [bap(tpIdx).curSnr2] );
                a2cell = num2cell( [bap(tpIdx_).curSnr2] );
                [ag(tpIdx).curSnr2] = a2cell{:};
                [ag(tpIdx_).curSnr2] = acell_curSnr2{:};
                %     acell = num2cell( [ag(tpIdx).dist2bisector] );
                %     acell2 = num2cell( [ag(tpIdx_).dist2bisector] );
                %     [ag(tpIdx).dist2bisector] = acell2{:};
                %     [ag(tpIdx_).dist2bisector] = acell{:};
                acell = num2cell( [bap(tpIdx).blockClass] );
                acell2 = num2cell( [bap(tpIdx_).blockClass] );
                [ag(tpIdx).blockClass] = acell2{:};
                [ag(tpIdx_).blockClass] = acell{:};
                acell = num2cell( [bap(tpIdx).gtAzm] );
                acell2 = num2cell( [bap(tpIdx_).gtAzm] );
                [ag(tpIdx).gtAzm] = acell2{:};
                [ag(tpIdx_).gtAzm] = acell{:};
            end
            
            [ag(isytR,:).posPresent] = deal( 1 );
            [ag(~isytR,:).posPresent] = deal( 0 );
            % acell_curSnr2 = repmat( num2cell( [bap(isyt).curSnr2] )', 1, size( ag, 2 ) );
            % [ag(isytR,:).posSnr] = acell_curSnr2{:};
            
            %% reshape assignments and aggregate baParams
            
            asgn{1}(:,1) = istp_(validBaps);
            asgn{2}(:,1) = istn_(validBaps);
            asgn{3}(:,1) = isfp_(validBaps);
            asgn{4}(:,1) = isfn_(validBaps);
            ag = ag(validBaps);
            
        end
        
        % -----------------------------------------------------------------
        
        function [ag, asgn, azmErrs] = aggregateBlockAnnotations3( bap, yp, yt )
            
            ag = bap;
            validBaps = ~isnan( arrayfun( @(ax)(ax.scpId), bap ) );
            
            istp = ((yp == yt) & (yp > 0));
            istn = ((yp == yt) & (yp < 0));
            isfp = ((yp ~= yt) & (yp > 0));
            isfn = ((yp ~= yt) & (yp < 0));
            
            isyt = yt > 0;
            isytR = any( isyt, 2 );
            
            %%
            
            azmErrs = arrayfun( @(x)(x.azmErr), bap );
            azmErrs2 = nanMean( azmErrs, 2 );
            azmErrs3 = nanStd( azmErrs, 2 );
            
            %% assign case-insensitive baParams changes
            
            % [ag.nAct_segStream] = deal( nan );
            acell_azmErrs2 = repmat( num2cell( azmErrs2 ), 1, size( ag, 2 ) );
            [ag(:,:).azmErr2] = acell_azmErrs2{:};
            acell_azmErrs3 = repmat( num2cell( azmErrs3 ), 1, size( ag, 2 ) );
            [ag(:,:).azmErr3] = acell_azmErrs3{:};
            acell_nyp = repmat( num2cell( sum( yp > 0, 2 ) ), 1, size( ag, 2 ) );
            [ag(:,:).nYp] = acell_nyp{:};
            
            %% assign case-sensitive baParams changes
            
            [ag(isytR,:).posPresent] = deal( 1 );
            [ag(~isytR,:).posPresent] = deal( 0 );
            
            %%
            
            asgn{1}(:,1) = istp(validBaps);
            asgn{2}(:,1) = istn(validBaps);
            asgn{3}(:,1) = isfp(validBaps);
            asgn{4}(:,1) = isfn(validBaps);
            ag = ag(validBaps);
            
        end

        % -----------------------------------------------------------------
        
        function baParamIdxs = baParams2bapIdxs( baParams )
            
            emptyBapi = PerformanceMeasures.BAC_BAextended.nanRescStruct;
            % emptyBapi = rmfield( emptyBapi, 'estAzm' );
            baParamIdxs = repmat( emptyBapi, numel( baParams ), 1);
            
            citmp = nan2inf( [baParams.classIdx] );
            natmp = nan2inf( [baParams.nAct] + 1 );
            nyptmp = nan2inf( [baParams.nYp] + 1 );
            % cstmp = nan2inf( round( ([baParams.curSnr]+35)/5 ) + 1 );
            % csdtmp = nan2inf( round( ([baParams.curSnr_db]+35)/5 ) + 1 );
            cs2tmp = nan2inf( round( ([baParams.curSnr2]+35)/5 ) + 1 );
            aetmp = nan2inf( round( [baParams.azmErr]/5 ) + 1 );
            ae2tmp = nan2inf( round( [baParams.azmErr2]/5 ) + 1 );
            ae3tmp = nan2inf( round( [baParams.azmErr3]/5 ) + 1 );
            gatmp = nan2inf( round( (wrapTo180([baParams.gtAzm])+180)/5 ) + 1 );
            eatmp = nan2inf( round( (wrapTo180([baParams.estAzm])+180)/5 ) + 1 );
            % nstmp = nan2inf( [baParams.nStream] + 1 );
            % nastmp = nan2inf( [baParams.nAct_segStream] + 1 );
            % cntmp = nan2inf( round( ([baParams.curNrj]+35)/5 ) + 1 );
            % cndtmp = nan2inf( round( ([baParams.curNrj_db]+35)/5 ) + 1 );
            % cnotmp = nan2inf( round( ([baParams.curNrjOthers]+35)/5 ) + 1 );
            % cnodtmp = nan2inf( round( ([baParams.curNrjOthers_db]+35)/5 ) + 1 );
            scptmp = nan2inf( [baParams.scpId] );
            scpetmp = nan2inf( max( 1, [baParams.scpId] - 255 + 1 ) );
            fitmp = nan2inf( [baParams.fileId] );
            fcitmp = nan2inf( [baParams.fileClassId] );
            pptmp = nan2inf( [baParams.posPresent] + 1 );
            % pstmp = nan2inf( round( ([baParams.posSnr]+35)/5 ) + 1 );
            bctmp = nan2inf( [baParams.blockClass] );
            % d2btmp = nan2inf( ([baParams.dist2bisector]+1)*10 + 1 );
            
            for ii = 1 : numel( baParams )
                baParamIdxs(ii).classIdx = citmp(ii);
                baParamIdxs(ii).nAct = natmp(ii);
                baParamIdxs(ii).nYp = nyptmp(ii);
                % baParamIdxs(ii).curSnr = cstmp(ii);
                % baParamIdxs(ii).curSnr_db = csdtmp(ii);
                baParamIdxs(ii).curSnr2 = cs2tmp(ii);
                baParamIdxs(ii).azmErr = aetmp(ii);
                baParamIdxs(ii).azmErr2 = ae2tmp(ii);
                baParamIdxs(ii).azmErr3 = ae3tmp(ii);
                baParamIdxs(ii).gtAzm = gatmp(ii);
                baParamIdxs(ii).estAzm = eatmp(ii);
                % baParamIdxs(ii).nStream = nstmp(ii);
                % baParamIdxs(ii).nAct_segStream = nastmp(ii);
                % baParamIdxs(ii).curNrj = cntmp(ii);
                % baParamIdxs(ii).curNrj_db = cndtmp(ii);
                % baParamIdxs(ii).curNrjOthers = cnotmp(ii);
                % baParamIdxs(ii).curNrjOthers_db = cnodtmp(ii);
                baParamIdxs(ii).scpId = scptmp(ii);
                baParamIdxs(ii).scpIdExt = scpetmp(ii);
                baParamIdxs(ii).fileId = fitmp(ii);
                baParamIdxs(ii).fileClassId = fcitmp(ii);
                baParamIdxs(ii).posPresent = pptmp(ii);
                % baParamIdxs(ii).posSnr = pstmp(ii);
                baParamIdxs(ii).blockClass = bctmp(ii);
                % baParamIdxs(ii).dist2bisector = d2btmp(ii);
            end
            
        end
        % -----------------------------------------------------------------
    end

end

