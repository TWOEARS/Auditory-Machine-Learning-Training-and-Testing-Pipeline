function signals = makeEarsignals( monoSound, angle, wp1sim )


wp1sim.Sources(1).AudioBuffer.setData( monoSound );
wp1sim.set('ReInit',true);
wp1sim.Sinks.removeData();

wp1sim.Sources(1).set('Azimuth', angle);

while ~wp1sim.Sources(1).isEmpty()
  wp1sim.set('Refresh',true);  % refresh all objects
  wp1sim.set('Process',true);  % processing 
end
signals = wp1sim.Sinks.getData();
signals = signals / max( abs( signals(:) ) ); % normalize



