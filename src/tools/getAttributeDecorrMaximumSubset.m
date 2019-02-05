function [attrVal,maxSubsets,tmp] = getAttributeDecorrMaximumSubset( resc, attrVar, depVars, mhReqs, msReqs, decorrVars )

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
firstSumDownKeepVars = unique( [1,attrVar,depVars,mhVars,decorrVars,msVars] );
attrVar_ = arrayfun( @(x)(find( x == firstSumDownKeepVars )), attrVar );
depVars_ = arrayfun( @(x)(find( x == firstSumDownKeepVars )), depVars );
decorrVars_ = arrayfun( @(x)(find( x == firstSumDownKeepVars )), decorrVars );
mhReqs_ = mhReqs;
if ~isempty( mhReqs )
    mhReqs_(:,1) = cellfun( @(c)(arrayfun( @(x)(find( x == firstSumDownKeepVars )), c)), mhReqs(:,1), 'UniformOutput', false );
    mhVars_ = [mhReqs_{:,1}];
else
    mhVars_ = [];
end
if ~isempty( msReqs )
    msReqs_ = cellfun( @(c)(arrayfun( @(x)(find( x == firstSumDownKeepVars )), c)), msReqs, 'UniformOutput', false );
    msVars_ = [msReqs_{:,1}];
else
    msReqs_ = msReqs;
    msVars_ = [];
end

tmp = resc.summarizeDown( firstSumDownKeepVars );
fprintf( '.' );

[tmp,maxSubsets] = cutDownToMaximumSubset( tmp, depVars_, mhReqs_, msReqs_ );
fprintf( '.' );

tmp = tmp.summarizeDown( unique( [attrVar_,depVars_,mhVars_,decorrVars_,msVars_] ) );
attrVar_ = attrVar_ - 1;
depVars_ = depVars_ - 1;
decorrVars_= decorrVars_ - 1;

attrs = unique( tmp.dataIdxs(:,attrVar_) );
tmpAttr = tmp.combineFun( @(varargin)(attrMultHelper( [varargin{:}], double(attrs') )), ...
                          attrVar_, attrs, 1, 'double' );

% ensure meaning down is done in proper order (as specified in function
% call)
decVars__ = sort( decorrVars_ );
if ~isequal( decVars__, decorrVars_ )
    tmpAttr.dataIdxs(:,decVars__) = tmpAttr.dataIdxs(:,decorrVars_);
    [tmpAttr.dataIdxs,sidxs] = sortrows( tmpAttr.dataIdxs );
    tmpAttr.data = tmpAttr.data(sidxs,:);
end

tmpm = tmpAttr.meanDown( depVars_, ':' );
fprintf( '.' );
attrVal = tmpm.resc2mat();
fprintf( '.' );

tmpVal = tmpm;
tmpVal.data = ones( size( tmpVal.data ) );
attrValid = squeeze( tmpVal.resc2mat() );
attrVal(~attrValid) = nan;

fprintf( '.\n' );

end


function aMean = attrMultHelper( aVals, aIdxs )
    aMean_1 = sum( aVals .* repmat( aIdxs, size( aVals, 1 ), 1 ), 2 );
    aMean_2 = sum( aVals, 2 );
    aMean = aMean_1 ./ aMean_2;
    aMean(aMean_2==0 & aMean_1==0) = 0;
end
