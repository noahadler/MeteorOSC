OscRecv recv;
3334 => recv.port;
recv.listen();

SinOsc s => ADSR adsr => dac;
0 => s.gain;
adsr.set(30::ms, 50::ms, 0.35, 495::ms);

function void spork_note() {
  1 => s.gain;
  1 => adsr.keyOn;
  0.25::second => now;
  1 => adsr.keyOff;
}

function void funky_beat() {
  
  <<<"Waiting for OSC messages">>>;
  while (true) {
    recv.event("/button,i") @=> OscEvent beat_event;

	beat_event => now;
	while (beat_event.nextMsg() != 0) {
	  beat_event.getInt() => int button_num;
	  <<< button_num >>>;
	  Std.mtof(48.0+button_num) => s.freq;
	  spork ~ spork_note();
	  
	}
  }

}

funky_beat();
