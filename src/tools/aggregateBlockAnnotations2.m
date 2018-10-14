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

asgn{1} = istp_(validBaps);
asgn{2} = istn_(validBaps);
asgn{3} = isfp_(validBaps);
asgn{4} = isfn_(validBaps);
ag = ag(validBaps);

end

