function blockSizes = getBlockSizes( niState )

blockSizes.winSamples = 2 * round( niState.wp2dataCreation.winSizeSec * niState.wp2dataCreation.fsHz / 2 );
blockSizes.hopSamples = 2 * round( niState.wp2dataCreation.hopSizeSec * niState.wp2dataCreation.fsHz / 2 );
blockSizes.blockSamples = niState.wp2dataCreation.fsHz * niState.blockCreation.blockSize;
blockSizes.shiftSamples = niState.wp2dataCreation.fsHz * niState.blockCreation.shiftSize;

blockSizes.hopsPerBlock = 2 * round( 0.5 * niState.blockCreation.blockSize / niState.wp2dataCreation.hopSizeSec ) - 1; % -1 because otherwise the last frame of a block would last until past the end of that block
blockSizes.hopsPerShift  = 2 * round( 0.5 * niState.blockCreation.shiftSize / niState.wp2dataCreation.hopSizeSec );


