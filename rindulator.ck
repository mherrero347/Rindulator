finished the plan, time to work on getting LiSa to create live input buffer base
d on trigger event (key trigger for now), but first I'm gonna mess around with t
he sample code!

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
