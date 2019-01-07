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

