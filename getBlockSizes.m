function [blockLen,shiftLen] = getBlockSizes( esetup, signal )

blockLen = 2 * round( 0.5 * esetup.blockCreation.blockSize * signal.FsHz ) - 1; % -1 because otherwise the last frame of a block would last until past the end of that block
shiftLen = 2 * round( 0.5 * esetup.blockCreation.shiftSize * signal.FsHz );


