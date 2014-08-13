function blockSizes = getBlockSizes( esetup )

blockSizes.winSamples = 2 * round( esetup.wp2dataCreation.winSizeSec * esetup.wp2dataCreation.fsHz / 2 );
blockSizes.hopSamples = 2 * round( esetup.wp2dataCreation.hopSizeSec * esetup.wp2dataCreation.fsHz / 2 );
blockSizes.blockSamples = esetup.wp2dataCreation.fsHz * esetup.blockCreation.blockSize;
blockSizes.shiftSamples = esetup.wp2dataCreation.fsHz * esetup.blockCreation.shiftSize;

blockSizes.hopsPerBlock = 2 * round( 0.5 * esetup.blockCreation.blockSize / esetup.wp2dataCreation.hopSizeSec ) - 1; % -1 because otherwise the last frame of a block would last until past the end of that block
blockSizes.hopsPerShift  = 2 * round( 0.5 * esetup.blockCreation.shiftSize / esetup.wp2dataCreation.hopSizeSec );


