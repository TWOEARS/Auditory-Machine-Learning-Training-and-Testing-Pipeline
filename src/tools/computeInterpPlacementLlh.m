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
llhTPplacement_stats = interpSmoothStats( ad_tmp, llhppad_tmp, azmsInterp, ...
                                          1000*(max( nsps ) + 1 - nsps), ...
                                          'pchip', {'sgolay', 18} );

end