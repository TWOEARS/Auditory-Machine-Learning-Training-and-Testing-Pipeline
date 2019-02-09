function [placementLlh_scp_azms,...
          pr_maxAzmErr_nyp1_scp,...
          pr_maxAzmErr_scp,...
          bapr_scp,...
          rs_scps] = getAzmPlacement( rs_b_pp, rs_t_pp, azmIdStr, maxCorrectAzmErr )

if nargin < 3, azmIdStr = 'gtAzm'; end
if nargin < 4, maxCorrectAzmErr = 0; end
maxCorrectAzmErrBAPI = round( maxCorrectAzmErr/5 ) + 1;

rsb_scps = unique( rs_b_pp.dataIdxs(:,[rs_b_pp.id.scpId,rs_b_pp.id.scpIdExt]), 'rows' );
rst_scps = unique( rs_t_pp.dataIdxs(:,[rs_t_pp.id.scpId,rs_t_pp.id.scpIdExt]), 'rows' );
if ~isequal( rsb_scps, rst_scps )
    error( 'rs_b and rs_t do not contain the same scenes' );
end
rs_scps = rsb_scps;

rs_b_tp = rs_b_pp.filter( rs_b_pp.id.counts, @(x)(x~=1) );
rs_b_tp = rs_b_tp.summarizeDown( getSumDownRsIds( rs_b_tp, azmIdStr ) );
if nargout > 1
    rs_t_pp_maxAzmErr_nyp1 = rs_t_pp.filter( rs_t_pp.id.nYp, @(x)(x~=2) );
    rs_t_pp_maxAzmErr_nyp1 = rs_t_pp_maxAzmErr_nyp1.filter( ...
                                   rs_t_pp_maxAzmErr_nyp1.id.azmErr, @(x)(x>maxCorrectAzmErrBAPI) );
    rs_t_pp_maxAzmErr_nyp1 = rs_t_pp_maxAzmErr_nyp1.summarizeDown( getSumDownRsIds( rs_t_pp_maxAzmErr_nyp1, azmIdStr ) );
    rs_t_pp_maxAzmErr = rs_t_pp.filter( rs_t_pp.id.azmErr, @(x)(x>maxCorrectAzmErrBAPI) );
    rs_t_pp_maxAzmErr = rs_t_pp_maxAzmErr.summarizeDown( getSumDownRsIds( rs_t_pp_maxAzmErr, azmIdStr ) );
    rs_t_pp = rs_t_pp.summarizeDown( getSumDownRsIds( rs_t_pp, azmIdStr ) );
    rs_b_tp_nyp1 = rs_b_pp.filter( rs_b_pp.id.counts, @(x)(x~=1) );
    rs_b_tp_nyp1 = rs_b_tp_nyp1.filter( rs_b_pp.id.nYp, @(x)(x~=2) );
    rs_b_tp_nyp1 = rs_b_tp_nyp1.summarizeDown( getSumDownRsIds( rs_b_tp_nyp1, azmIdStr ) );
    rs_b_tp_nyp234 = rs_b_pp.filter( rs_b_pp.id.counts, @(x)(x~=1) );
    rs_b_tp_nyp234 = rs_b_tp_nyp234.filter( rs_b_pp.id.nYp, @(x)(x<3) );
    rs_b_tp_nyp234 = rs_b_tp_nyp234.summarizeDown( getSumDownRsIds( rs_b_tp_nyp234, azmIdStr ) );
    rs_b_fn_nyp123 = rs_b_pp.filter( rs_b_pp.id.counts, @(x)(x~=4) );
    rs_b_fn_nyp123 = rs_b_fn_nyp123.filter( rs_b_pp.id.nYp, @(x)(x==1) );
    rs_b_fn_nyp123 = rs_b_fn_nyp123.summarizeDown( getSumDownRsIds( rs_b_fn_nyp123, azmIdStr ) );
end
rs_b_fp_pp = rs_b_pp.filter( rs_b_pp.id.counts, @(x)(x~=3) );
rs_b_fp_pp = rs_b_fp_pp.summarizeDown( getSumDownRsIds( rs_b_fp_pp, azmIdStr ) );
rs_b_fn_pp = rs_b_pp.filter( rs_b_pp.id.counts, @(x)(x~=4) );
rs_b_fn_pp = rs_b_fn_pp.summarizeDown( getSumDownRsIds( rs_b_fn_pp, azmIdStr ) );
rs_b_tn_pp = rs_b_pp.filter( rs_b_pp.id.counts, @(x)(x~=2) );
rs_b_tn_pp = rs_b_tn_pp.summarizeDown( getSumDownRsIds( rs_b_tn_pp, azmIdStr ) );

posCounts_scp_azms = zeros( size( rs_scps, 1 ), 73 );
negCounts_scp_azms = zeros( size( rs_scps, 1 ), 73 );
counts_t_pp_scp = zeros( size( rs_scps, 1 ), 1 );
counts_t_pp_maxAzmErr_nyp1_scp = zeros( size( rs_scps, 1 ), 1 );
counts_t_pp_maxAzmErr_scp = zeros( size( rs_scps, 1 ), 1 );
counts_b_tp_nyp1 = zeros( size( rs_scps, 1 ), 1 );
counts_b_tp_nyp234 = zeros( size( rs_scps, 1 ), 1 );
counts_b_fn_nyp123 = zeros( size( rs_scps, 1 ), 1 );

for ii = 1 : size( rs_scps, 1 )
    
    rs_b_tp_scpii = getSceneResc( rs_b_tp, rs_scps(ii,1), rs_scps(ii,2) );
    if nargout > 1
        rs_b_tp_nyp1_scpii = getSceneResc( rs_b_tp_nyp1, rs_scps(ii,1), rs_scps(ii,2) );
        rs_b_tp_nyp234_scpii = getSceneResc( rs_b_tp_nyp234, rs_scps(ii,1), rs_scps(ii,2) );
        rs_b_fn_nyp123_scpii = getSceneResc( rs_b_fn_nyp123, rs_scps(ii,1), rs_scps(ii,2) );
        rs_t_pp_scpii = getSceneResc( rs_t_pp, rs_scps(ii,1), rs_scps(ii,2) );
        rs_t_pp_maxAzmErr_nyp1_scpii = getSceneResc( rs_t_pp_maxAzmErr_nyp1, rs_scps(ii,1), rs_scps(ii,2) );
        rs_t_pp_maxAzmErr_scpii = getSceneResc( rs_t_pp_maxAzmErr, rs_scps(ii,1), rs_scps(ii,2) );
    end
    rs_b_fp_scpii = getSceneResc( rs_b_fp_pp, rs_scps(ii,1), rs_scps(ii,2) );
    rs_b_fn_scpii = getSceneResc( rs_b_fn_pp, rs_scps(ii,1), rs_scps(ii,2) );
    rs_b_tn_scpii = getSceneResc( rs_b_tn_pp, rs_scps(ii,1), rs_scps(ii,2) );
    
    eids_combs_b_tp = unique( rs_b_tp_scpii.dataIdxs(:,getEssentialIds( rs_b_tp_scpii, azmIdStr )), 'rows' );
    eids_combs_b_fp = unique( rs_b_fp_scpii.dataIdxs(:,getEssentialIds( rs_b_fp_scpii, azmIdStr )), 'rows' );
    eids_combs_b_fn = unique( rs_b_fn_scpii.dataIdxs(:,getEssentialIds( rs_b_fn_scpii, azmIdStr )), 'rows' );
    eids_combs_b_tn = unique( rs_b_tn_scpii.dataIdxs(:,getEssentialIds( rs_b_tn_scpii, azmIdStr )), 'rows' );
    eids_combs_b = unique( cat( 1, eids_combs_b_tp, eids_combs_b_fp, eids_combs_b_fn, eids_combs_b_tn ), 'rows' );
    combs_notIn_b_tp = setdiff( eids_combs_b, eids_combs_b_tp, 'rows' );
    combs_notIn_b_fp = setdiff( eids_combs_b, eids_combs_b_fp, 'rows' );
    combs_notIn_b_fn = setdiff( eids_combs_b, eids_combs_b_fn, 'rows' );
    combs_notIn_b_tn = setdiff( eids_combs_b, eids_combs_b_tn, 'rows' );
    if nargout > 1
        eids_combs_b_tp_nyp1 = unique( rs_b_tp_nyp1_scpii.dataIdxs(:,getEssentialIds( rs_b_tp_nyp1_scpii, azmIdStr )), 'rows' );
        eids_combs_b_tp_nyp234 = unique( rs_b_tp_nyp234_scpii.dataIdxs(:,getEssentialIds( rs_b_tp_nyp234_scpii, azmIdStr )), 'rows' );
        eids_combs_b_fn_nyp123 = unique( rs_b_fn_nyp123_scpii.dataIdxs(:,getEssentialIds( rs_b_fn_nyp123_scpii, azmIdStr )), 'rows' );
        eids_combs_b = unique( cat( 1, eids_combs_b_tp_nyp1, eids_combs_b_tp_nyp234, eids_combs_b_fn_nyp123 ), 'rows' );
        combs_notIn_b_tp_nyp1 = setdiff( eids_combs_b, eids_combs_b_tp_nyp1, 'rows' );
        combs_notIn_b_tp_nyp234 = setdiff( eids_combs_b, eids_combs_b_tp_nyp234, 'rows' );
        combs_notIn_b_fn_nyp123 = setdiff( eids_combs_b, eids_combs_b_fn_nyp123, 'rows' );
        eids_combs_t_pp = unique( rs_t_pp_scpii.dataIdxs(:,getEssentialIds( rs_t_pp_scpii, azmIdStr )), 'rows' );
        eids_combs_t_pp_maxAzmErr_nyp1 = unique( rs_t_pp_maxAzmErr_nyp1_scpii.dataIdxs(:,getEssentialIds( rs_t_pp_maxAzmErr_nyp1_scpii, azmIdStr )), 'rows' );
        eids_combs_t_pp_maxAzmErr = unique( rs_t_pp_maxAzmErr_scpii.dataIdxs(:,getEssentialIds( rs_t_pp_maxAzmErr_scpii, azmIdStr )), 'rows' );
        eids_combs_t = unique( cat( 1, eids_combs_t_pp, eids_combs_t_pp_maxAzmErr_nyp1, eids_combs_t_pp_maxAzmErr ), 'rows' );
        combs_notIn_t_pp_maxAzmErr_nyp1 = setdiff( eids_combs_t, eids_combs_t_pp_maxAzmErr_nyp1, 'rows' );
        combs_notIn_t_pp_maxAzmErr = setdiff( eids_combs_t, eids_combs_t_pp_maxAzmErr, 'rows' );
        combs_notIn_t_pp = setdiff( eids_combs_t, eids_combs_t_pp, 'rows' );

    
        % b_tp_nyp1
        counts_ii_b_tp_nyp1 = getCounts1( rs_b_tp_nyp1_scpii, combs_notIn_b_tp_nyp1, ...
                                          1, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, 'scpId' );
        counts_b_tp_nyp1(ii,1) = nanSum( counts_ii_b_tp_nyp1(:) );

        % b_tp_nyp234
        counts_ii_b_tp_nyp234 = getCounts1( rs_b_tp_nyp234_scpii, combs_notIn_b_tp_nyp234, ...
                                            1, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, 'scpId' );
        counts_b_tp_nyp234(ii,1) = nanSum( counts_ii_b_tp_nyp234(:) );

        % b_fn_nyp123
        counts_ii_b_fn_nyp123 = getCounts1( rs_b_fn_nyp123_scpii, combs_notIn_b_fn_nyp123, ...
                                            4, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, 'scpId' );
        counts_b_fn_nyp123(ii,1) = nanSum( counts_ii_b_fn_nyp123(:) );

        % t_pp
        t_pp_scpii_fnLidxs = rs_t_pp_scpii.dataIdxs(:,rs_t_pp_scpii.id.counts) == 4;
        tmp_di = rs_t_pp_scpii.dataIdxs(t_pp_scpii_fnLidxs,:);
        tmp_d = rs_t_pp_scpii.data(t_pp_scpii_fnLidxs,:);
        rs_t_pp_scpii.data(t_pp_scpii_fnLidxs,:) = [];
        rs_t_pp_scpii.dataIdxs(t_pp_scpii_fnLidxs,:) = [];
        rs_t_pp_scpii.dataIdxs(:,rs_t_pp_scpii.id.counts) = 14;
        tmp_di(:,rs_t_pp_scpii.id.counts) = 14;
        rs_t_pp_scpii = rs_t_pp_scpii.addData( tmp_di, tmp_d, true );
        counts_ii_t_pp = getCounts1( rs_t_pp_scpii, combs_notIn_t_pp, ...
                                     14, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, 'scpId' );
        counts_t_pp_scp(ii,1) = nanSum( counts_ii_t_pp(:) );

        % t_tp_maxAzmErr_nyp1
        counts_ii_t_pp_maxAzmErr_nyp1 = getCounts1( rs_t_pp_maxAzmErr_nyp1_scpii, combs_notIn_t_pp_maxAzmErr_nyp1, ...
                                                    1, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, 'scpId' );
        counts_t_pp_maxAzmErr_nyp1_scp(ii,1) = nanSum( counts_ii_t_pp_maxAzmErr_nyp1(:) );

        % t_tp_maxAzmErr
        counts_ii_t_pp_maxAzmErr = getCounts1( rs_t_pp_maxAzmErr_scpii, combs_notIn_t_pp_maxAzmErr, ...
                                               1, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, 'scpId' );
        counts_t_pp_maxAzmErr_scp(ii,1) = nanSum( counts_ii_t_pp_maxAzmErr(:) );

    end
    
    % b_tp
    azmDist_counts_ii_tp = getCounts1( rs_b_tp_scpii, combs_notIn_b_tp, ...
                                       1, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, azmIdStr );
    
    % b_fp
    azmDist_counts_ii_fp = getCounts1( rs_b_fp_scpii, combs_notIn_b_fp, ...
                                       3, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, azmIdStr );
    
    % b_fn
    azmDist_counts_ii_fn = getCounts1( rs_b_fn_scpii, combs_notIn_b_fn, ...
                                       4, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, azmIdStr );
    
    % b_tn
    azmDist_counts_ii_tn = getCounts1( rs_b_tn_scpii, combs_notIn_b_tn, ...
                                       2, rs_scps(ii,1), rs_scps(ii,2), azmIdStr, azmIdStr );
    
    azmDist_posCounts_ii = nan( 2, max( numel( azmDist_counts_ii_tp ), numel( azmDist_counts_ii_fp ) ) );
    azmDist_posCounts_ii(1,1:numel( azmDist_counts_ii_tp )) = azmDist_counts_ii_tp;
    azmDist_posCounts_ii(2,1:numel( azmDist_counts_ii_fp )) = azmDist_counts_ii_fp;
    posCounts_scp_azms(ii,1:size( azmDist_posCounts_ii, 2 )) = nanSum( azmDist_posCounts_ii, 1 );
    azmDist_negCounts_ii = nan( 2, max( numel( azmDist_counts_ii_tn ), numel( azmDist_counts_ii_fn ) ) );
    azmDist_negCounts_ii(1,1:numel( azmDist_counts_ii_tn )) = azmDist_counts_ii_tn;
    azmDist_negCounts_ii(2,1:numel( azmDist_counts_ii_fn )) = azmDist_counts_ii_fn;
    negCounts_scp_azms(ii,1:size( azmDist_negCounts_ii, 2 )) = nanSum( azmDist_negCounts_ii, 1 );

    counts_interpol_lidxs = posCounts_scp_azms(ii,:) > 0 & negCounts_scp_azms(ii,:) == 0;
    counts_interpol_lidxs_ = [counts_interpol_lidxs,counts_interpol_lidxs,counts_interpol_lidxs];
    negCounts_scp_azms_ = [negCounts_scp_azms(ii,:),negCounts_scp_azms(ii,:),negCounts_scp_azms(ii,:)];
    negCounts_scp_azms_(counts_interpol_lidxs_) = ...
        interp1( find( ~counts_interpol_lidxs_ ), negCounts_scp_azms_(~counts_interpol_lidxs_),...
                 find( counts_interpol_lidxs_ ) );
    negCounts_scp_azms(ii,counts_interpol_lidxs) = negCounts_scp_azms_(73+find( counts_interpol_lidxs ));

end %for ii = 1 : size( rs_scps, 1 )

% posCounts_scp_azms = smoothdata( posCounts_scp_azms, 2, 'sgolay', maxCorrectAzmErrBAPI*2 );
% negCounts_scp_azms = smoothdata( negCounts_scp_azms, 2, 'sgolay', maxCorrectAzmErrBAPI*2 );
posCounts_scp_azms(posCounts_scp_azms<0) = 0;
negCounts_scp_azms(negCounts_scp_azms<0) = 0;
posNegCounts_scp_azms = nanSum( cat( 3, posCounts_scp_azms, negCounts_scp_azms ), 3 );
posCounts_scp_azms(posNegCounts_scp_azms < 0.05 * max( posNegCounts_scp_azms(:) )) = 0;
posNegCounts_scp_azms(posNegCounts_scp_azms < 0.05 * max( posNegCounts_scp_azms(:) )) = 0;
placementLlh_scp_azms = posCounts_scp_azms ./ posNegCounts_scp_azms;
if nargout > 1
    pr_maxAzmErr_nyp1_scp = counts_t_pp_maxAzmErr_nyp1_scp ./ counts_t_pp_scp;
    pr_maxAzmErr_scp = counts_t_pp_maxAzmErr_scp ./ counts_t_pp_scp;
    bapr_scp = counts_b_tp_nyp1 ./ (counts_b_tp_nyp1 + counts_b_tp_nyp234 + counts_b_fn_nyp123);
end

end %function

function sumDown_rs_ids = getSumDownRsIds( rs, azmIdStr )
    if isfield( rs.id, azmIdStr )
        sumDown_rs_ids = [rs.id.counts,rs.id.classIdx,rs.id.fileClassId,rs.id.fileId,rs.id.(azmIdStr),rs.id.scpId,rs.id.scpIdExt];
    else
        sumDown_rs_ids = [rs.id.counts,rs.id.classIdx,rs.id.fileClassId,rs.id.fileId,rs.id.scpId,rs.id.scpIdExt];
    end
end

function eids = getEssentialIds( rs, azmIdStr )
    if isfield( rs.id, azmIdStr )
        eids = [rs.id.classIdx,rs.id.fileClassId,rs.id.fileId,rs.id.(azmIdStr)];
    else
        eids = [rs.id.classIdx,rs.id.fileClassId,rs.id.fileId];
    end
end

function counts = getCounts1( rs, eids_notIncluded_butNeeded, c_rep, scpid, scpide, azmIdStr, countsDepId )
    if ~isempty( rs.dataIdxs ) && ~isempty( eids_notIncluded_butNeeded )
        combs_notUsed_dataIdxs = zeros( size( eids_notIncluded_butNeeded, 1 ), size( rs.dataIdxs, 2 ) );
        combs_notUsed_dataIdxs(:,rs.id.classIdx) = eids_notIncluded_butNeeded(:,1);
        combs_notUsed_dataIdxs(:,rs.id.counts) = c_rep;
        combs_notUsed_dataIdxs(:,rs.id.fileClassId) = eids_notIncluded_butNeeded(:,2);
        combs_notUsed_dataIdxs(:,rs.id.fileId) = eids_notIncluded_butNeeded(:,3);
        combs_notUsed_dataIdxs(:,rs.id.scpId) = scpid;
        combs_notUsed_dataIdxs(:,rs.id.scpIdExt) = scpide;
        if isfield( rs.id, azmIdStr )
            combs_notUsed_dataIdxs(:,rs.id.(azmIdStr)) = eids_notIncluded_butNeeded(:,4);
        end
        rs = rs.addData( combs_notUsed_dataIdxs, zeros( size( combs_notUsed_dataIdxs, 1 ), 1 ), true );
    end
    df255maxFactor = 255 / max( rs.data );
    cid = size( rs.dataIdxs, 2 ) + 1;
    rs.dataIdxs(:,cid) = round( rs.data * df255maxFactor );
    rs.id.cid = cid;
    if ~isempty( rs.data )
        counts = getAttributeDecorrMaximumSubset( rs, rs.id.cid, ...
            [rs.id.(countsDepId)], ...
            {[rs.id.classIdx],[],false;},...
            {},...
            [rs.id.fileClassId,rs.id.fileId] );
    else
        counts = zeros( 1, 0 );
    end
    counts = counts / df255maxFactor;
end
