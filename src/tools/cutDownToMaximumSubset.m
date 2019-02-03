function [cutResc,maxSubsets] = cutDownToMaximumSubset( resc, depVars, mhVars, msVars )

remove_lidxs = false( size( resc.dataIdxs, 1 ), 1 );

sens_lidxs = resc.dataIdxs(:,1) == 1 | resc.dataIdxs(:,1) == 4 | resc.dataIdxs(:,1) == 5 | resc.dataIdxs(:,1) == 6;
spec_lidxs = ~sens_lidxs;

for ui = {sens_lidxs,spec_lidxs}

    use_lidxs = ui{1};
    
    depVals = unique( resc.dataIdxs(use_lidxs,depVars), 'rows' );
    reqMhVals = {};
    for ii = 1:size( mhVars, 1 )
        if ~isempty( mhVars{ii,2} )
            reqMhVals{ii} = double( mhVars{ii,2} );
            if mhVars{ii,3}
                mhVars_lidxs = false( size( resc.dataIdxs, 1 ), 1 );
                for jj = 1:size( mhVars{ii,2}, 1 )
                    mhVars_lidxs = mhVars_lidxs | ~any( bsxfun( @minus, int16(resc.dataIdxs(:,mhVars{ii,1})), int16(mhVars{ii,2}(jj,:)) ), 2 );
                end
                remove_lidxs = remove_lidxs | (use_lidxs & ~mhVars_lidxs);
            end
        else
            reqMhVals{ii} = double( unique( resc.dataIdxs(use_lidxs,mhVars{ii,1}), 'rows' ) );
        end
    end
    if ~isempty( mhVars )
        warnstate = warning( 'off', 'ALLCOMB:EmptyInput' );
        reqMhVals = uint8( allcomb( reqMhVals{:} ) );
        warning( warnstate );
    else
        reqMhVals = [];
        mhVars = cell( 0, 1 );
    end
    
    for ii = 1:size( depVals, 1 )
        depVals_ii_lidxs = use_lidxs & ~any( bsxfun( @minus, int16(resc.dataIdxs(:,depVars)), int16(depVals(ii,:)) ), 2 );
        depVals_ii_dataIdxs = unique( resc.dataIdxs(depVals_ii_lidxs,[mhVars{:,1}]), 'rows' );
        for jj = 1:size( reqMhVals, 1 )
            allMhValsThere = any( ~any( bsxfun( @minus, int16(depVals_ii_dataIdxs), int16(reqMhVals(jj,:)) ), 2 ), 1 );
            if ~allMhValsThere
                remove_lidxs = remove_lidxs | depVals_ii_lidxs;
                break;
            end
        end
    end
    
end

cutResc = resc;
cutResc.data(remove_lidxs,:) = [];
cutResc.dataIdxs(remove_lidxs,:) = [];

remove_lidxs = false( size( cutResc.dataIdxs, 1 ), 1 );

sens_lidxs = cutResc.dataIdxs(:,1) == 1 | cutResc.dataIdxs(:,1) == 5 | cutResc.dataIdxs(:,1) == 6;
spec_lidxs = ~sens_lidxs;

maxSubsets = {};
if isempty( msVars ), return; end

depMhVars = unique( [depVars,[mhVars{:,1}]] );
msVars(:,2) = cellfun( @(c)(arrayfun( @(x)(find( x == depMhVars )), c)), msVars(:,2), 'UniformOutput', false );
for ui = {sens_lidxs,spec_lidxs}

    use_lidxs = ui{1};
 
    depMhVals = unique( cutResc.dataIdxs(use_lidxs,depMhVars), 'rows' );
    maxSubsets_ = cell( size( msVars, 1 ) );
    depMhVals_ = {};
    for jj = 1:numel( maxSubsets_ )
        if ~isempty( msVars{jj,2} )
            unq_depMhVals_idim = unique( depMhVals(:,msVars{jj,2}), 'rows' );
            for dd = 1:size( unq_depMhVals_idim, 1)
                depMhVals_{dd} = depMhVals(all(depMhVals(:,msVars{jj,2})==unq_depMhVals_idim(dd,:),2),:);
            end
        else
            depMhVals_ = {depMhVals};
            unq_depMhVals_idim = 1;
        end
        for dd = 1:numel( depMhVals_ )
            maxSubset = [];
            if size( depMhVals_{dd}, 1 ) > 0
                depMhVals_lidxs = ~remove_lidxs & use_lidxs & ~any( bsxfun( @minus, int16(cutResc.dataIdxs(:,depMhVars)), int16(depMhVals_{dd}(1,:)) ), 2 );
                maxSubset = unique( cutResc.dataIdxs(depMhVals_lidxs,msVars{jj,1}), 'rows' );
            end
            for ii = 2:size( depMhVals_{dd}, 1 )
                depMhVals_lidxs = ~remove_lidxs & use_lidxs & ~any( bsxfun( @minus, int16(cutResc.dataIdxs(:,depMhVars)), int16(depMhVals_{dd}(ii,:)) ), 2 );
                maxSubset = intersect( maxSubset,...
                    unique( cutResc.dataIdxs(depMhVals_lidxs,msVars{jj,1}), 'rows' ), ...
                    'rows' );
                if isempty( maxSubset ), break; end
            end
            maxSubsets_{jj}{dd} = {maxSubset,unq_depMhVals_idim(dd,:)};
            notMsVals_lidxs = use_lidxs & any( size( maxSubset ) );
            if ~isempty( msVars{jj,2} )
                notMsVals_lidxs = notMsVals_lidxs & ...
                        ~any( bsxfun( @minus, int16(cutResc.dataIdxs(:,msVars{jj,2})), int16(unq_depMhVals_idim(dd,:)) ), 2 );
            end
            for ii = 1:size( maxSubset, 1 )
                notMsVals_lidxs = notMsVals_lidxs & ...
                    any( bsxfun( @minus, int16(cutResc.dataIdxs(:,msVars{jj,1})), int16(maxSubset(ii,:)) ), 2 );
            end
            remove_lidxs = remove_lidxs | notMsVals_lidxs ;
        end
    end
    maxSubsets = [maxSubsets, maxSubsets_'];
end

cutResc.data(remove_lidxs,:) = [];
cutResc.dataIdxs(remove_lidxs,:) = [];

end
