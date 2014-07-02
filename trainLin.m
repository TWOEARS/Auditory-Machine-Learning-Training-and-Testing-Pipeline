function [labelsTest, instancesTest, model] = trainLin( labels, instances, testsetRatio, cvFolds )
    
[ltr, labelsTest, dtr, instancesTest] = splitDataPermutation( labels, instances, testsetRatio );

dtr = sparse( dtr );
[ba, bs, bc, bcn, bcp] = gridLinTrain( dtr, ltr, cvFolds );
linParamString = sprintf( '-s %d -c %e -w-1 %e -w1 %e -q', bs, bc, bcn, bcp );
model = liblinTrain( ltr, dtr, linParamString );

