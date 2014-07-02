function signals = makeEarsignals( monoSound, angle, niState )

head = Head( niState.wp2dataCreation.head, niState.wp2dataCreation.fsHz );
hrirs = head.getHrirs( angle );

convLength = ceil( niState.wp2dataCreation.fsHz / head.fs * head.numSamples );
signals = zeros( length( monoSound ) + convLength - 1, 2 );

signals(:,1) = conv( monoSound, hrirs(:, 1) );
signals(:,2) = conv( monoSound, hrirs(:, 2) );

