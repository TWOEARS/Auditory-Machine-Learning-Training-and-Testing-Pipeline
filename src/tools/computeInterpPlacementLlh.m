function [llhTPplacement_stats,azmsInterp] = computeInterpPlacementLlh( llhPosPlacement_scp_azms, ...
                                                                        sceneDescr, ...
                                                                        azmFactor, ...
                                                                        allowFBc, ...
                                                                        azmSpanType, ...
                                                                        nsps, ...
                                                                        azmErrRange, ...
                                                                        useGtCorrectedAzmDistance )

if nargin < 3 || isempty( azmFactor )
    azmFactor = 5;
end

if nargin < 4|| isempty( allowFBc )
    allowFBc = true;
end

if nargin < 5
    azmSpanType = [];
end
% azmSpanTypes -- 1: nose inbetween, 2: ear inbetween, 3: one quadrant

if nargin < 6 || isempty( nsps )
    nsps = 1 : (max( arrayfun( @(a)(numel(a.azms)), sceneDescr ) ) - 1);
end

if nargin < 7 || isempty( azmErrRange )
    azmErrRange = [0 180];
end

if nargin < 8 || isempty( useGtCorrectedAzmDistance )
    useGtCorrectedAzmDistance = false;
end

tAzms = arrayfun( @(s)(s.azms(1)), sceneDescr );

for nsp = nsps
    llhPosPlacements_azmDists = cell( 1, 180 / azmFactor + 1 ); % 0..72 * 2.5 = 0..180°
    for ii = 1 : numel( llhPosPlacement_scp_azms )
        if isnan( llhPosPlacement_scp_azms( ii ) ), continue; end
        [scpIdx_ii,azmsIdx_ii] = ind2sub( size( llhPosPlacement_scp_azms ), ii );
        azm_ii = (azmsIdx_ii - 1) * azmFactor - 180;
        azms_scp_ii = wrapTo180( sceneDescr(scpIdx_ii).azms );
        [~,azm_ii_tmpIdx] = min( abs( wrapTo180( azms_scp_ii - azm_ii ) ) );
        azm_ii_gtCorrected = sceneDescr(scpIdx_ii).azms(azm_ii_tmpIdx);
        azm_ii_error = abs( wrapTo180( azm_ii_gtCorrected - azm_ii ) );
        if azm_ii_error < azmErrRange(1) || azm_ii_error > azmErrRange(2)
            continue;
        end
        azm_ii_ = wrapTo180( azm_ii );
        if ~isempty( azmSpanType ) && (abs( azm_ii_ - tAzms(scpIdx_ii) ) > 0.1)
            if abs( azm_ii_ ) == 180, azm_ii_ = azm_ii_ * sign( tAzms(scpIdx_ii)+eps ); end
            if (sign( azm_ii_ ) + sign( tAzms(scpIdx_ii) ) == 0) % nose inbetween
                if azmSpanType ~= 1, continue; end
            elseif (min( abs( azm_ii_ ), abs( tAzms(scpIdx_ii) ) ) < 90) && ...
                    (max( abs( azm_ii_ ), abs( tAzms(scpIdx_ii) ) ) > 90) % ear inbetween
                if azmSpanType ~= 2, continue; end
            else
                if azmSpanType ~= 3, continue; end
            end
        end
        if ~allowFBc && abs( sin( deg2rad( tAzms(scpIdx_ii) ) ) - sin( deg2rad( azm_ii_gtCorrected ) ) ) < 0.01
            continue;
        end
        nnPosAzmDist_scp_ii = unique( abs( wrapTo180( azms_scp_ii(2:end) - tAzms(scpIdx_ii) ) ) );
        azmDist_ii = abs( wrapTo180( azm_ii - tAzms(scpIdx_ii) ) );
        azmDist_ii_gtCorrected = abs( wrapTo180( azm_ii_gtCorrected - tAzms(scpIdx_ii) ) );
        if azmDist_ii_gtCorrected ~= 0 && ...
                numel( nnPosAzmDist_scp_ii ) < nsp
            continue;
        end
        if azmDist_ii_gtCorrected ~= 0 && ...
                abs( azmDist_ii_gtCorrected - nnPosAzmDist_scp_ii(nsp)) > 1
            continue;
        end
        if useGtCorrectedAzmDistance
            azmDistIdx_ii = round( azmDist_ii_gtCorrected / azmFactor ) + 1;
        else
            azmDistIdx_ii = round( azmDist_ii / azmFactor ) + 1;
        end
        llhPosPlacements_azmDists{azmDistIdx_ii} = ...
            [llhPosPlacements_azmDists{azmDistIdx_ii}, llhPosPlacement_scp_azms(ii)];
    end
    noPlacement_azmIdxs = cellfun( @isempty, llhPosPlacements_azmDists );
    azmDists = (0:180 / azmFactor) * azmFactor;
    azmDists(noPlacement_azmIdxs) = [];
    llhPosPlacements_azmDists(noPlacement_azmIdxs) = [];
    
    ad_tmp{nsp} = azmDists;
    llhppad_tmp{nsp} = llhPosPlacements_azmDists;
end

azmsInterp = 0:2.5:180;
redist_llhValues = nan( 0, numel( azmsInterp ) );
for nsp = nsps
    llhppad_tmp_nsp = cellfun( @sort, llhppad_tmp{nsp}, 'un', false );
    ad_tmp_nsp = ad_tmp{nsp};
    if numel( llhppad_tmp_nsp ) == 1 && ad_tmp_nsp == 0
        continue;
    end
    redist_llhIdx_nsp = 0;
    redist_llhIdxMax_nsp = cellfun( @numel, llhppad_tmp_nsp );
    nUseAzms = max( ceil( (numel( llhppad_tmp_nsp ) - 1) / 3 ), min( 4, numel( ad_tmp_nsp )-1 ) );
    sampleAzmsRange = ceil( (numel( llhppad_tmp_nsp ) - 1) / nUseAzms );
    sampled_llhppad = nan( 1, nUseAzms+1 );
    sampled_azms = nan( 1, nUseAzms+1 );
    sampled_azms(1) = ad_tmp_nsp(1);
    for jj = 1 : 1000*(max( arrayfun( @(a)(numel(a.azms)), sceneDescr ) )-nsp)
        redist_llhIdx_nsp_ = ceil( max( min( (redist_llhIdx_nsp + randn()*0.01), 1 ), 0+eps ) ...
                                   * redist_llhIdxMax_nsp(1) );
        sampled_llhppad(1) = llhppad_tmp_nsp{1}(redist_llhIdx_nsp_);
        redist_llhIdx_nsp = redist_llhIdx_nsp + 0.01;
        if redist_llhIdx_nsp > 1
            redist_llhIdx_nsp = 0;
        end
        useAzmIdx = sampleAzmsRange * (0 : nUseAzms-1) + 1 + randi( sampleAzmsRange, 1, nUseAzms );
        useAzmIdx = unique( min( [useAzmIdx; repmat( numel( llhppad_tmp_nsp ), 1, nUseAzms )], [], 1 ) );
        if numel( useAzmIdx ) ~= nUseAzms
            useAzmIdx = unique( [1, useAzmIdx, useAzmIdx - 1] );
            useAzmIdx(1+randperm( numel( useAzmIdx )-1, numel( useAzmIdx ) - nUseAzms - 1)) = [];
            useAzmIdx(1) = [];
        end
        sampled_azms(2:end) = ad_tmp_nsp(useAzmIdx);
        for ii = 1 : nUseAzms
            redist_llhIdx_nsp_ = ceil( max( min( (redist_llhIdx_nsp + randn()*0.01), 1 ), 0+eps ) ...
                                       * redist_llhIdxMax_nsp(useAzmIdx(ii)) );
            sampled_llhppad(ii+1) = llhppad_tmp_nsp{useAzmIdx(ii)}(redist_llhIdx_nsp_);
        end
        redist_llhValues(end+1,:) = interp1( sampled_azms, sampled_llhppad, azmsInterp, 'pchip', nan );
    end
end

llhTPplacement_stats(1,:) = median( redist_llhValues, 1, 'omitnan' );
llhTPplacement_stats(2,:) = quantile( redist_llhValues, 0.75, 1 );
llhTPplacement_stats(3,:) = quantile( redist_llhValues, 0.25, 1 );
sLlh = sort( redist_llhValues );
ncSllh = sum( ~isnan( sLlh ), 1 );
ncSllh = max( ncSllh, ones( size( ncSllh ) ) );
indIdxs = sub2ind( size( sLlh ), min( ncSllh, ceil( 1 + ncSllh/2 + 1.96*sqrt( ncSllh )/2 ) ), 1 : size( sLlh, 2 ) );
llhTPplacement_stats(4,:) = sLlh(indIdxs);
indIdxs = sub2ind( size( sLlh ), max( ones( size( ncSllh ) ), floor( ncSllh/2 - 1.96*sqrt( ncSllh )/2 ) ), 1 : size( sLlh, 2 ) );
llhTPplacement_stats(5,:) = sLlh(indIdxs);
% https://www.ucl.ac.uk/child-health/short-courses-events/about-statistical-courses/statistics-and-research-methods/chapter-8-content-2
llhTPplacement_stats(6,:) = nanMean( redist_llhValues, 1 );
llhIsNan = isnan( llhTPplacement_stats );
llhTPplacement_stats_ = smoothdata( llhTPplacement_stats, 2, 'sgolay', 18 );
llhTPplacement_stats_(:,1:8) = repmat( 1:-1/7:0, 6, 1 ) .* llhTPplacement_stats(:,1:8) ...
                             + repmat( 0:1/7:1, 6, 1 ) .* llhTPplacement_stats_(:,1:8);
llhTPplacement_stats = llhTPplacement_stats_;
llhTPplacement_stats(llhIsNan) = nan;


end