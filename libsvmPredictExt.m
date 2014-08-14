function [pred, val, dec] = libsvmPredictExt( y, x, model, translators, factors )

x = scaleData( x, translators, factors );

[pred, ~, dec] = libsvmpredict(y, x, model, '-b 1');
if model.Label(1) < 0;
  pred = pred * -1;
end
val = validation_function(pred, y);
