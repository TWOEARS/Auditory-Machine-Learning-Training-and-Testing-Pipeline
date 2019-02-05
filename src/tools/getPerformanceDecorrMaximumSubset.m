function [sens,spec,maxSubsets,sensCIs,specCIs,tmp] = getPerformanceDecorrMaximumSubset( resc, depVars, mhReqs, msReqs, decorrVars )

if ~isempty( mhReqs )
    mhVars = [mhReqs{:,1}];
else
    mhVars = [];
end
if ~isempty( msReqs )
    msVars = [msReqs{:,1}];
else
    msVars = [];
end
firstSumDownKeepVars = unique( [1,depVars,mhVars,decorrVars,msVars] );
depVars_ = arrayfun( @(x)(find( x == firstSumDownKeepVars )), depVars );
decVars_ = arrayfun( @(x)(find( x == firstSumDownKeepVars )), decorrVars );
mhReqs_ = mhReqs;
if ~isempty( mhReqs )
    mhReqs_(:,1) = cellfun( @(c)(arrayfun( @(x)(find( x == firstSumDownKeepVars )), c)), mhReqs(:,1), 'UniformOutput', false );
end
if ~isempty( msReqs )
    msReqs_ = cellfun( @(c)(arrayfun( @(x)(find( x == firstSumDownKeepVars )), c)), msReqs, 'UniformOutput', false );
else
    msReqs_ = msReqs;
end

tmp = resc.summarizeDown( firstSumDownKeepVars );
fprintf( '.' );
% if nargout > 3
%     tmp1 = tmp.combineFun( @(x,y)(binofithelper(x,y,1)), 1, [1,4], 5, 'double' ); %lCI_sens
%     tmp2 = tmp.combineFun( @(x,y)(binofithelper(x,y,2)), 1, [1,4], 6, 'double' ); %uCI_sens
% end
tmp  = tmp.combineFun( @(x,y)(x./(x+y)), 1, [1,4], 1, 'double' ); %sens
fprintf( '.' );
% if nargout > 3
%     tmp1 = tmp1.combineFun( @(x,y)(binofithelper(x,y,1)), 1, [2,3], 7, 'double' ); %lCI_spec
%     tmp2 = tmp2.combineFun( @(x,y)(binofithelper(x,y,2)), 1, [2,3], 8, 'double' ); %uCI_spec
% end
tmp  = tmp.combineFun( @(x,y)(x./(x+y)), 1, [2,3], 2, 'double' ); %spec
fprintf( '.' );
% if nargout > 3
%     tmp  = tmp.addData( tmp1.dataIdxs, tmp1.data );
%     tmp  = tmp.addData( tmp2.dataIdxs, tmp2.data );
% end

[tmp,maxSubsets] = cutDownToMaximumSubset( tmp, depVars_, mhReqs_, msReqs_ );
fprintf( '.' );

% ensure meaning down is done in proper order (as specified in function
% call)
decVars__ = sort( decVars_ );
if ~isequal( decVars__, decVars_ )
    tmp.dataIdxs(:,decVars__) = tmp.dataIdxs(:,decVars_);
    [tmp.dataIdxs,sidxs] = sortrows( tmp.dataIdxs );
    tmp.data = tmp.data(sidxs,:);
end

tmpm = tmp.meanDown( [1,depVars_], ':' );
fprintf( '.' );
perf = tmpm.resc2mat();
fprintf( '.' );

tmpVal = tmpm;
tmpVal.data = ones( size( tmpVal.data ) );
perfVal = squeeze( tmpVal.resc2mat() );
perf(~perfVal) = nan;

sens = squeeze( perf(1,:,:) );
if size( perf, 1 ) > 1
    spec = squeeze( perf(2,:,:) );
else
    spec = [];
end
% if nargout > 3
%     sensCIs = squeeze( perf(5:6,:,:) );
%     specCIs = squeeze( perf(7:8,:,:) );
% end

if nargout > 3
    tmp1 = tmp.summarizeDown( [1,depVars_], ':', [], @(x)(normCIhelper(x,1)) );
    fprintf( '.' );
    tmp2 = tmp.summarizeDown( [1,depVars_], ':', [], @(x)(normCIhelper(x,2)) );
    fprintf( '.' );
    perfCIUs = tmp1.resc2mat();
    perfCIUs(~perfVal) = nan;
    perfCILs = tmp2.resc2mat();
    perfCILs(~perfVal) = nan;
    sensCIs = squeeze( cat( 1, perfCIUs(1,:,:), perfCILs(1,:,:) ) );
    if size( perfCIUs, 1 ) > 1
        specCIs = squeeze( cat( 1, perfCIUs(2,:,:), perfCILs(2,:,:) ) );
    else
        specCIs = [];
    end
else
    sensCIs = [];
    specCIs = [];
end

if ~isempty( sensCIs ) && ~all( isnan( sensCIs(:) ) )
    if size( sens, 1 ) == 1
        sensCIs = shiftdim( shiftdim( flip( abs( sensCIs - cat( 1, sens, sens ) ), 1 ), +1 ), -1 );
    else
        sensCIs = shiftdim( flip( abs( sensCIs - cat( 1, shiftdim( sens, -1 ), shiftdim( sens, -1 ) ) ), 1 ), +1 );
    end
end
if ~isempty( specCIs ) && ~all( isnan( specCIs(:) ) )
    if size( spec, 1 ) == 1
        specCIs = shiftdim( shiftdim( flip( abs( specCIs - cat( 1, spec, spec ) ), 1 ), +1 ), -1 );
    else
        specCIs = shiftdim( flip( abs( specCIs - cat( 1, shiftdim( spec, -1 ), shiftdim( spec, -1 ) ) ), 1 ), +1 );
    end
end
fprintf( '.\n' );

end


function ci = binofithelper( x, y, idx )
    [~,ci] = binofit( round(x), round(x)+round(y) );
    ci = ci(idx);
end

function ci = normCIhelper( x, idx )
    [~,~,ci] = normfit( x );
    ci = ci(idx);
end
