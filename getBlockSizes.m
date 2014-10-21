function [blockLen,shiftLen] = getBlockSizes( setup, signal )

blockLen = 2 * round( 0.5 * setup.blockCreation.blockSize * signal.FsHz ) - 1; % -1 because otherwise the last frame of a block would last until past the end of that block
shiftLen = 2 * round( 0.5 * setup.blockCreation.shiftSize * signal.FsHz );


