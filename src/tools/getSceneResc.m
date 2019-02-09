function rs_scp = getSceneResc( rs, scpid, scpide )

rs_scp = rs.filter( rs.id.scpId, @(x)(x ~= scpid) );
rs_scp = rs_scp.filter( rs_scp.id.scpIdExt, @(x)(x ~= scpide) );

end

