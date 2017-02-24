//File - Rindulator.ck
//---------------------------------
// I'm imagining sorta like rinding an orange, that skimming off of the
// skin of an orange using a knife. Basically, this could be a sort of
// effect that you'd put on a voice or some incoming signal. When the
// signal exceeds some volume limit, it starts filling up the buffer,
// and once the buffer is filled, the buffer is sorta rindulated, where
// the program grain-synthesizes the first x samples from the head of the
// buffer (aka, a grain is created and played of size x samples), and the
// program plays that grain for some amount of time (probably short) and
// then adds the next n number of samples to the end of the grain, takes
// the first n off, and then rinse-and-repeat with this new grain, until
// the end of the buffer is reached. Also, I'm thinking a linear gain
// envelope, because like you know whatever...

// Parameters:
// buffer_size(?) - size of the buffer that needs to be filled before
//                  the rindulator kicks into rindulation
// step_size - the number of samples that get appended to the end of
//             the grain (and removed from front) each step of the rindulator
// grain_play_length - the length of time for which a grain is played
//                     before the rindulator steps
// grain_size - number of samples in the sound grain

// Control Parameters:
// grain_tuning - the pitch of the grain
// grain_position_randomness - adding a little randomness to where the playhead
//                             of the grain begins?

// Rough Algorithm:
// Monitoring input...
// When(trigger event - either when noise gate exceeded/ trigger key pressed)
//    fill up the buffer
//    rindulate the buffer
//       initiate buffer with first grain_size samples
//       while (not at end of buffer)
//            play the grain (with appropriate control parameters) for grain_play_length time
//            step grain forward (append new samples, remove front samples)

// ---- Globals/Constants ---- //
Hid hi;
HidMsg msg;
LiSa lisa;
3::second => dur BUFFER_DUR;
50::ms => dur GRAIN_DUR;
1::second => dur GRAIN_PLAY_DUR;

44 => int SPACE_BAR_KEY;
82 => int UP_KEY;
81 => int DOWN_KEY;
26 => int W_KEY;
22 => int S_KEY;

0 => int GRAIN_TUNE_MIN;
2 => int GRAIN_TUNE_MAX;
.000001 => float GRAIN_POS_RAND_MIN;
1 => float GRAIN_POS_RAND_MAX;

// ---- Control Parameters ---- //
1 => float grain_tuning;
GRAIN_POS_RAND_MIN => float grain_pos_rand;

// --- Setting up LiSa ---- //
lisa => dac;


// ---- Buffer Recording ---- //
fun void fill_buffer() {
    adc => lisa;

    adc =< lisa;
}

// ---- KEYBOARD MONITORING --- //

0 => int device;
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

// keyboard
fun void key_monitor_shred() {
    // infinite event loop
    while(true) {
        // wait on HidIn as event
        hi => now;
        
        // messages received
        while(hi.recv(msg)) {
            // button down
            if(msg.isButtonDown()) {
                if(msg.which == SPACE_BAR_KEY) {
                    spork ~ fill_buffer();
                } else if (msg.which == UP_KEY) {
                    0.005 +=> grain_tuning;
                    if(grain_tuning > GRAIN_TUNE_MAX) GRAIN_TUNE_MAX => grain_tuning;
                } else if (msg.which == DOWN_KEY) {
                    0.005 -=> grain_tuning;
                    if(grain_tuning < GRAIN_TUNE_MIN) GRAIN_TUNE_MIN => grain_tuning;
                } else if (msg.which == W_KEY) {
                    1.1 *=> grain_pos_rand;
                    if(grain_pos_rand > GRAIN_POS_RAND_MAX) GRAIN_POS_RAND_MAX => grain_pos_rand;
                } else if (msg.which == S_KEY) {
                    .9 *=> grain_pos_rand;
                    if(grain_pos_rand < GRAIN_POS_RAND_MIN) GRAIN_POS_RAND_MIN => grain_pos_rand;
                }
            }
        }
    }
}

// ---- PSUEDO-MAIN ---- //
spork ~ key_monitor_shred();
while(1::second => now){};
