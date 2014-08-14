function [model, translators, factors, trVal] = libsvmtrainExt( y, x, paramStr )

%% calculate proportion of positive examples / the respective weight

ypShare = (mean(y) + 1 ) * 0.5;
cp = (1-ypShare)/ypShare;

%% modify paramStr to this weight

cpPos = strfind( paramStr, '-w1 ' );
if ~isempty( cpPos )
   str1 = paramStr(1:cpPos+2);
   cpPos2 = strfind( paramStr(cpPos+4:end), ' ' );
   str2 = paramStr(cpPos+4+cpPos2:end);
   paramStr = sprintf( '%s %e %s', str1, cp, str2 );
end

%% scale training data to zero mean, unit variance

[xscaled, translators, factors] = scaleTrainingData( x );

%% train model

paramStr = sprintf( '%s -m 500 -h 1', paramStr );
disp( ['training with ' paramStr] );
model = libsvmtrain( y, xscaled, paramStr );

%% evaluate performance of model on training data

disp( 'training performance:' );
[~, trVal, ~] = libsvmPredictExt( y, x, model, translators, factors );

end