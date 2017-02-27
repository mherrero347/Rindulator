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

// MAKE SURE TO CITE CODE

// ------------------------------------------------------------
//                   START GLOBALS/ CONSTANTS
// ------------------------------------------------------------

// ---- Lisa Setup ---- //
LiSa lisa => dac;
3 ::second => dur BUFFER_DUR;
lisa.duration(BUFFER_DUR);
lisa.maxVoices(30);
lisa.gain(.5);
lisa.recRamp(10::ms);
reset_lisa();
lisa => dac;

// ---- Rindulation Position Oscillator ---- //
SinOsc rindPosOsc => blackhole;
rindPosOsc.freq(.1);
rindPosOsc.gain(0.4);
rindPosOsc.phase(0.5);

// ---- Key Monitoring Constants/ Globals ---- //
// Global Objects/ Setup
Hid hi;
HidMsg msg;

// Constants
44 => int SPACE_BAR_KEY;
82 => int UP_KEY;
81 => int DOWN_KEY;
26 => int W_KEY;
22 => int S_KEY;

// ---- Grain Parameters/ Constants --- //
// Grain Constants
50::ms => dur GRAIN_DUR;
1::second => dur GRAIN_PLAY_DUR;
10 => int GRAIN_FIRE_RAND;
.5 => float GRAIN_RAMP_FACTOR;

// Grain Control Parameters/ Bounding Constants)
0 => int GRAIN_TUNE_MIN;
2 => int GRAIN_TUNE_MAX;
.001 => float GRAIN_POS_RAND_MIN;
1 => float GRAIN_POS_RAND_MAX;

1 => float grain_tuning;
GRAIN_POS_RAND_MIN => float grain_pos_rand;

// ------------------------------------------------------------
//                   END GLOBALS/ CONSTANTS
// ------------------------------------------------------------

// ------------------------------------------------------------
//                   START KEYBOARD MONITORING
// ------------------------------------------------------------
//0 = U, 1 = Down, 2 = W, 3 = S
int keyState[4];
for(0 => int i; i < keyState.size(); i++) {
    0 => keyState[i];
}

//open the keyboard device
0 => int device;
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>; 

fun void control_param_changer() {
    while(100::ms => now){
        //up
        if (keyState[0]){
            0.005 +=> grain_tuning;
            if(grain_tuning > GRAIN_TUNE_MAX) GRAIN_TUNE_MAX => grain_tuning;
            //down
        } if (keyState[1]) {
            0.005 -=> grain_tuning;
            if(grain_tuning < GRAIN_TUNE_MIN) GRAIN_TUNE_MIN => grain_tuning;
            //w
        } if (keyState[2]) {
            1.1 *=> grain_pos_rand;
            if(grain_pos_rand > GRAIN_POS_RAND_MAX) GRAIN_POS_RAND_MAX => grain_pos_rand;
            //s
        } if (keyState[3]) {
            .9 *=> grain_pos_rand;
            if(grain_pos_rand < GRAIN_POS_RAND_MIN) GRAIN_POS_RAND_MIN => grain_pos_rand;
        }
    }
}

// keyboard
fun void key_monitor_shred() {
    while(true) {
        hi => now;
        // messages received
        while(hi.recv(msg)) {
            if(msg.which == SPACE_BAR_KEY && msg.isButtonDown()) {
                spork ~ fill_buffer();
                BUFFER_DUR + 10::samp => now;
                spork ~ rindulate();
            } else if (msg.which == UP_KEY) {
                msg.isButtonDown() => keyState[0];
            } else if (msg.which == DOWN_KEY) {
                msg.isButtonDown() => keyState[1];
            } else if (msg.which == W_KEY) {
                msg.isButtonDown() => keyState[2];
            } else if (msg.which == S_KEY) {
                msg.isButtonDown() => keyState[3];
            }
        }
    }
}

// ------------------------------------------------------------
//                   END KEYBOARD MONITORING
// ------------------------------------------------------------

// ------------------------------------------------------------
//                   BEGIN LISA FUNCTIONS
// ------------------------------------------------------------

// ---- Buffer Recording ---- //
fun void fill_buffer() {
    adc => lisa;  
    lisa.record(1);
    BUFFER_DUR => now; 
    lisa.record(0);
    adc =< lisa;
}

fun void reset_lisa(){
    lisa.clear();
    lisa.playPos(0);
    lisa.record(0);'
    lisa.play(0);
}

// ------------------------------------------------------------
//                   END LISA FUNCTIONS
// ------------------------------------------------------------

// ------------------------------------------------------------
//                   START RINDULATION FUNCTIONS
// ------------------------------------------------------------

fun void rindulate() {
      spork ~ print();
      now + 20::second => time rind_later;
      while(now < rind_later){
          now + GRAIN_PLAY_DUR => time step_later;
          while(now < step_later){
              fireGrain(rindPosOsc.last() + 0.5);
              GRAIN_DUR / 8 + Math.random2f(0,GRAIN_FIRE_RAND)::ms => now;
          }
      }
      reset_lisa();
}


fun void fireGrain(float grainPos)
{
    // grain length
    GRAIN_DUR => dur grainDur;
    // ramp time
    GRAIN_DUR * GRAIN_RAMP_FACTOR => dur rampTime;
    // play pos
    grainPos + Math.random2f(0, grain_pos_rand) => float pos;
    // a grain
    if( lisa != null && pos >= 0 ) {
        spork ~ grain(pos * lisa.duration(), grainDur, rampTime, rampTime, grain_tuning);
    }
}

// grain sporkee
fun void grain(dur pos, dur grainLen, dur rampUp, dur rampDown, float rate )
{   
    // get a voice to use
    lisa.getVoice() => int voice;
    
    // if available
    if( voice > -1 )
    {
        // set rate
        lisa.rate( voice, rate );
        // set playhead
        lisa.playPos( voice, pos );
        // ramp up
        lisa.rampUp( voice, rampUp );
        // wait
        (grainLen - rampUp) => now;
        // ramp down
        lisa.rampDown( voice, rampDown );
        // wait
        rampDown => now;
    }
}

// print
fun void print()
{
    // time loop
    while( true )
    {
        // values
        <<< "pos rand:", grain_pos_rand, "grain tuning:", grain_tuning>>>;
        // advance time
        100::ms => now;
    }
}

// ------------------------------------------------------------
//                   END RINDULATION FUNCTIONS
// ------------------------------------------------------------

// ------------------------------------------------------------
//                   PSUEDO-MAIN/ OUTER INFINITE LOOP
// ------------------------------------------------------------
spork ~ key_monitor_shred();
spork ~ control_param_changer();
while(1::second => now){};
