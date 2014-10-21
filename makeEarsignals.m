function signals = makeEarsignals( monoSound, angle, sim )


sim.Sources(1).AudioBuffer.setData( monoSound );
sim.set('ReInit',true);
sim.Sinks.removeData();

sim.Sources(1).set('Azimuth', angle);

while ~sim.Sources(1).isEmpty()
  sim.set('Refresh',true);  % refresh all objects
  sim.set('Process',true);  % processing 
end
signals = normalise(sim.Sinks.getData());
