function baParamIdxs = baParams2bapIdxs( baParams )

emptyBapi = nanRescStruct;
% emptyBapi = rmfield( emptyBapi, 'estAzm' );
baParamIdxs = repmat( emptyBapi, numel( baParams ), 1);

citmp = nan2inf( [baParams.classIdx] );
natmp = nan2inf( [baParams.nAct] + 1 );
% cstmp = nan2inf( round( ([baParams.curSnr]+35)/5 ) + 1 );
% csdtmp = nan2inf( round( ([baParams.curSnr_db]+35)/5 ) + 1 );
cs2tmp = nan2inf( round( ([baParams.curSnr2]+35)/5 ) + 1 );
aetmp = nan2inf( round( [baParams.azmErr]/5 ) + 1 );
ae2tmp = nan2inf( round( [baParams.azmErr2]/5 ) + 1 );
gatmp = nan2inf( round( (wrapTo180([baParams.gtAzm])+180)/5 ) + 1 );
eatmp = nan2inf( round( (wrapTo180([baParams.estAzm])+180)/2.5 ) + 1 );
% nstmp = nan2inf( [baParams.nStream] + 1 );
% nastmp = nan2inf( [baParams.nAct_segStream] + 1 );
cntmp = nan2inf( round( ([baParams.curNrj]+35)/5 ) + 1 );
% cndtmp = nan2inf( round( ([baParams.curNrj_db]+35)/5 ) + 1 );
cnotmp = nan2inf( round( ([baParams.curNrjOthers]+35)/5 ) + 1 );
% cnodtmp = nan2inf( round( ([baParams.curNrjOthers_db]+35)/5 ) + 1 );
scptmp = nan2inf( [baParams.scpId] );
scpetmp = nan2inf( max( 1, [baParams.scpId] - 255 + 1 ) );
fitmp = nan2inf( [baParams.fileId] );
fcitmp = nan2inf( [baParams.fileClassId] );
pptmp = nan2inf( [baParams.posPresent] + 1 );
pstmp = nan2inf( round( ([baParams.posSnr]+35)/5 ) + 1 );
bctmp = nan2inf( [baParams.blockClass] );
% d2btmp = nan2inf( ([baParams.dist2bisector]+1)*10 + 1 );

for ii = 1 : numel( baParams )
baParamIdxs(ii).classIdx = citmp(ii);
baParamIdxs(ii).nAct = natmp(ii);
% baParamIdxs(ii).curSnr = cstmp(ii);
% baParamIdxs(ii).curSnr_db = csdtmp(ii);
baParamIdxs(ii).curSnr2 = cs2tmp(ii);
baParamIdxs(ii).azmErr = aetmp(ii);
baParamIdxs(ii).azmErr2 = ae2tmp(ii);
baParamIdxs(ii).gtAzm = gatmp(ii);
baParamIdxs(ii).estAzm = eatmp(ii);
% baParamIdxs(ii).nStream = nstmp(ii);
% baParamIdxs(ii).nAct_segStream = nastmp(ii);
baParamIdxs(ii).curNrj = cntmp(ii);
% baParamIdxs(ii).curNrj_db = cndtmp(ii);
baParamIdxs(ii).curNrjOthers = cnotmp(ii);
% baParamIdxs(ii).curNrjOthers_db = cnodtmp(ii);
baParamIdxs(ii).scpId = scptmp(ii);
baParamIdxs(ii).scpIdExt = scpetmp(ii);
baParamIdxs(ii).fileId = fitmp(ii);
baParamIdxs(ii).fileClassId = fcitmp(ii);
baParamIdxs(ii).posPresent = pptmp(ii);
baParamIdxs(ii).posSnr = pstmp(ii);
baParamIdxs(ii).blockClass = bctmp(ii);
% baParamIdxs(ii).dist2bisector = d2btmp(ii);
end

end

function v = nan2inf( v )
v(isnan( v ))= inf;
end