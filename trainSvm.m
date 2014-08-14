function [model, translators, factors, predGenVal, hps, trVal] = trainSvm( foldsIdx, lfolds, dfolds, idfolds, esetup, calcProbs )

%% search for the best hyperparameters, using the folds indexed by foldsIdx

hps = gridSvmTrain( foldsIdx, lfolds, dfolds, idfolds, esetup );
predGenVal = hps(end,5);

%% train with the best hyperparameters, using all folds

svmParamString = sprintf( '-t %d -g %e -c %e -w-1 1 -w1 %e -q -e %e -b %d', hps(end,1), hps(end,4), hps(end,3), 1, hps(end,2), calcProbs );
disp( '' );
fprintf( '\ntraining with best hyperparameters (CV gen prediction: %g)\n', predGenVal );

[model, translators, factors, trVal] = libsvmtrainExt( vertcat( lfolds{foldsIdx} ), vertcat( dfolds{foldsIdx} ), svmParamString );

