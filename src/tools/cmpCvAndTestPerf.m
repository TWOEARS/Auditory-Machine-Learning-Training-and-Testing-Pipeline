function [testPerfu, cvPerfu, cvStdu, ncu, lu] = cmpCvAndTestPerf( testModelDir, bPlot, plotTitle )

testModelDirEntry = dir( [testModelDir filesep '*.model.mat'] );
testModelVars = load( [testModelDir filesep testModelDirEntry.name] );

lambdas = testModelVars.model.model.lambda;
nc = sum( abs( testModelVars.model.model.beta ) > 0 );

cvPerf = testModelVars.model.lPerfsMean';
cvStd = testModelVars.model.lPerfsStd';

nc0i = (nc == 0);
nc(nc0i) = [];
cvPerf(nc0i) = [];
cvStd(nc0i) = [];
lambdas(nc0i) = [];

testPerf = double( testModelVars.testPerfresults );
if numel( testPerf ) == 1 % only for best lambda
    testLambda = testModelVars.model.lambda;
elseif numel( testPerf ) == numel( testModelVars.model.model.lambda )
    testPerf(nc0i) = [];
else
    error( 'duh' );
end

[ncu, ~, ncui] = unique( nc );
for ii = 1 : length( ncu )
    if numel( testPerf ) == numel( lambdas ), testPerfu(ii) = mean( testPerf(ncui==ii) ); end
    cvPerfu(ii) = mean( cvPerf(ncui==ii) );
    cvStdu(ii) = mean( cvStd(ncui==ii) );
    lu(ii) = mean( lambdas(ncui==ii) );
end

if numel( testPerf ) == 1
    ncu_test = nc(lambdas == testLambda);
    testPerfu = testPerf;
else
    ncu_test = ncu;
end

if nargin >= 2 && bPlot
    fig = figure;
    hCvPlot = mseb( ncu, cvPerfu, cvStdu );
    ax = gca;
    set( ax, 'XScale', 'log' );
    hold all;
    if numel( testPerf ) == 1
        hTestPlot = plot( ncu_test, testPerfu, 'gx', 'LineWidth', 3 );
    else
        hTestPlot = plot( ncu_test, testPerfu, 'g', 'LineWidth', 3 );
    end
    xlabel( '# of coefficients' );
    ylabel( 'Performance' );
    legend( 'cvPerf', 'testPerf', 'Location', 'best' );
    if nargin >= 3
        title( plotTitle );
    end
    set( ax, 'XLim', [ncu(1), ncu(end)] );
end