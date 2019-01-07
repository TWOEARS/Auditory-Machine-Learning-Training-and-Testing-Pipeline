function [baParams, asgn] = extractBAparams( blockAnnotations, scp, yp, yt )

asgn{1} = ((yp == yt) & (yp > 0));
asgn{2} = ((yp == yt) & (yp < 0));
asgn{3} = ((yp ~= yt) & (yp > 0));
asgn{4} = ((yp ~= yt) & (yp < 0));

emptyBap = nanRescStruct;
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