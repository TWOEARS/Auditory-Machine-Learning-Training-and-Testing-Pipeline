function eval_exp_maxData()
    
addpath( '../..' );
startIdentificationTraining();

if exist( '../expsTest/pds_expsMaxData_test.mat', 'file' )
    t1 = load( '../expsTest/pds_expsMaxData_test.mat' );
else
    warning( 'mat file not found' );
    return;
end
if exist( '../expsTest/pds_glmnet_test.mat', 'file' )
    t2 = load( '../expsTest/pds_glmnet_test.mat' );
else
    warning( 'mat file not found' );
    return;
end

tPerf = cell( 10, 1 );
trTime = cell( 10, 1 );
nc = cell( 10, 1 );

for ddt = 2
for cc = 1 : 2
for ff = 2
for ss = 1
for aa = [1 4 9]
for mds = 1 : 5
for bd = [0 1]
    
idx = mds+5*bd;
if mds < 5

mdsv = [5000 15000 30000 50000];
if ~any( cellfun( @(x)(all(x==[cc ddt ss ff aa mdsv(mds) bd])), t1.doneCfgsTest ) )
    continue; % testing not done
end

%     t1.coefIdxs_b{cc,dd,ss,ff,aa,find(mds==[5000 15000 30000 50000]),bd+1};
    nc{idx} = [nc{idx} t1.nCoefs_b{cc,ddt-1,ss,ff,aa,mds,bd+1} ];
    tPerf{idx} = [tPerf{idx} t1.test_performances_b{cc,ddt-1,ss,ff,aa,mds,bd+1} ];
    trTime{idx} = [trTime{idx} t1.trainTime{cc,ddt-1,ss,ff,aa,mds,bd+1}.trainTime ];
else
    nc{idx} = [nc{idx} t2.nCoefs_b{cc,ddt,ss,ff,aa,ss,aa} ];
    tPerf{idx} = [tPerf{idx} t2.test_performances_b{cc,ddt,ss,ff,aa,ss,aa} ];
    trTime{idx} = [trTime{idx} t2.trainTime{cc,ddt,ss,ff,aa,ss,aa}.trainTime ];
end

end
end
end
end
end
end
end

perfDiffBorNot = cell( 5, 1 );
for ii = 1 : 5
    perfDiffBorNot{ii} = tPerf{ii+5} - tPerf{ii};
end
perfDiff = cell( 4, 1 );
for ii = 1 : 4
    perfDiff{ii} = tPerf{5} - tPerf{ii};
end
perfDiffB = cell( 4, 1 );
for ii = 1 : 4
    perfDiffB{ii} = tPerf{5} - tPerf{ii+5};
end
ncDiffB = cell( 4, 1 );
for ii = 1 : 4
    ncDiffB{ii} = nc{5} - nc{ii+5};
end

figure;
boxplot_grps( ...
    {'5e3', '15e3', '30e3', '50e3', '75e3', '5e3 b', '15e3 b', '30e3 b', '50e3 b', '75e3 b'}, ...
    [1 1 1 1 3 2 2 2 2 3], ...
    {'notch', 'off', 'whisker', inf, 'widths', 0.8}, ...
    nc{:} );
boxplot_performance( 'tPerf', ...
    {'5e3', '15e3', '30e3', '50e3', '75e3', '5e3 b', '15e3 b', '30e3 b', '50e3 b', '75e3 b'}, ...
    [1 1 1 1 3 2 2 2 2 3], ...
    {'notch', 'off', 'whisker', inf, 'widths', 0.8}, ...
    tPerf{:} );
boxplot_performance( 'tPerf: Diff Bal vs UnBal. Bal is reference', ...
    {'5e3', '15e3', '30e3', '50e3', '75e3'}, ...
    [1 1 1 1 3], ...
    {'notch', 'off', 'whisker', inf, 'widths', 0.8}, ...
    perfDiffBorNot{:} );
boxplot_performance( 'tPerf: Diff vs Full set (reference)', ...
    {'5e3', '15e3', '30e3', '50e3'}, ...
    [1 1 1 1], ...
    {'notch', 'off', 'whisker', inf, 'widths', 0.8}, ...
    perfDiff{:} );
boxplot_performance( 'tPerf: Bal Diff vs Full set (reference)', ...
    {'5e3', '15e3', '30e3', '50e3'}, ...
    [1 1 1 1], ...
    {'notch', 'off', 'whisker', inf, 'widths', 0.8}, ...
    perfDiffB{:} );
figure;
boxplot_grps( ...
    {'5e3', '15e3', '30e3', '50e3'}, ...
    [1 1 1 1], ...
    {'notch', 'off', 'whisker', inf, 'widths', 0.8}, ...
    ncDiffB{:} );
figure;
boxplot_grps( ...
    {'5e3', '15e3', '30e3', '50e3', '75e3', '5e3 b', '15e3 b', '30e3 b', '50e3 b', '75e3 b'}, ...
    [1 1 1 1 3 2 2 2 2 3], ...
    {'notch', 'off', 'whisker', inf, 'widths', 0.8}, ...
    trTime{:} );
