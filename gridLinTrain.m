function [bestAcc, bestSolver, bestC, bestCn, bestCp] = gridLinTrain( trInstances, trLabels, cvFolds )

lpShare = (mean(trLabels) + 1 ) * 0.5;

bestAcc = 0;
for solver = [1 6 7]
for c = logspace( -4, 4, 9 )
for cn = [1]
for cp = [(1-lpShare)/lpShare]
    linParamString = sprintf( '-s %d -c %e -w-1 %e -w1 %e -v %d -q', solver, c, cn, cp, cvFolds);
    disp( ['cv with ' linParamString] );
    acc = liblinTrain( trLabels, trInstances, linParamString );
    if acc > bestAcc
        bestAcc = acc;
        bestSolver = solver;
        bestC = c;
        bestCn = cn;
        bestCp = cp;
    end
end
end
end
end
