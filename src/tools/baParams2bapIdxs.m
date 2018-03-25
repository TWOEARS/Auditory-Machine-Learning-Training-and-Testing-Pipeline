function baParamIdxs = baParams2bapIdxs( baParams )

emptyBapi = nanRescStruct;
emptyBapi = rmfield( emptyBapi, 'estAzm' );
baParamIdxs = repmat( emptyBapi, numel( baParams ), 1);

for ii = 1 : numel( baParams )
baParamIdxs(ii).classIdx =        nan2inf( baParams(ii).classIdx );
baParamIdxs(ii).nAct =            nan2inf( baParams(ii).nAct + 1 );
baParamIdxs(ii).curSnr =          nan2inf( round( (baParams(ii).curSnr+35)/5 ) + 1 );
baParamIdxs(ii).curSnr_db =       nan2inf( round( (baParams(ii).curSnr_db+35)/5 ) + 1 );
baParamIdxs(ii).curSnr2 =         nan2inf( round( (baParams(ii).curSnr2+35)/5 ) + 1 );
baParamIdxs(ii).azmErr =          nan2inf( round( baParams(ii).azmErr/5 ) + 1 );
baParamIdxs(ii).azmErr2 =         nan2inf( round( baParams(ii).azmErr2/5 ) + 1 );
baParamIdxs(ii).gtAzm =           nan2inf( round( (wrapTo180(baParams(ii).gtAzm)+180)/5 ) + 1 );
baParamIdxs(ii).nStream =         nan2inf( baParams(ii).nStream + 1 );
baParamIdxs(ii).nAct_segStream =  nan2inf( baParams(ii).nAct_segStream + 1 );
baParamIdxs(ii).curNrj =          nan2inf( round( (baParams(ii).curNrj+35)/5 ) + 1 );
baParamIdxs(ii).curNrj_db =       nan2inf( round( (baParams(ii).curNrj_db+35)/5 ) + 1 );
baParamIdxs(ii).curNrjOthers =    nan2inf( round( (baParams(ii).curNrjOthers+35)/5 ) + 1 );
baParamIdxs(ii).curNrjOthers_db = nan2inf( round( (baParams(ii).curNrjOthers_db+35)/5 ) + 1 );
baParamIdxs(ii).scpId =           nan2inf( baParams(ii).scpId );
baParamIdxs(ii).scpIdExt =        nan2inf( max( 1, baParams(ii).scpId - 255 + 1 ) );
baParamIdxs(ii).fileId =          nan2inf( baParams(ii).fileId );
baParamIdxs(ii).fileClassId =     nan2inf( baParams(ii).fileClassId );
baParamIdxs(ii).posPresent =      nan2inf( baParams(ii).posPresent + 1 );
baParamIdxs(ii).posSnr =          nan2inf( round( (baParams(ii).posSnr+35)/5 ) + 1 );
baParamIdxs(ii).blockClass =      nan2inf( baParams(ii).blockClass );
baParamIdxs(ii).dist2bisector =   nan2inf( (baParams(ii).dist2bisector+1)*10 + 1 );
end

end

function v = nan2inf( v )
v(isnan( v ))= inf;
end