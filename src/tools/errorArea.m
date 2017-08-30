function errorArea( x, y1, y2, color )
%ERRORAREA Plots a continous shaded error area at x between y1 and y2
%   Detailed explanation goes here
X=[x, fliplr(x)];                
Y=[ y1, fliplr( y2 ) ]; 
fill(X, Y, color, 'linestyle','none', 'FaceAlpha', 0.1);
end

