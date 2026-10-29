'use strict';
/* Original four-show chiptune score. Deliberately not a transcription of broadcast themes.
 * Frequencies are MIDI note numbers; -1 is a rest. Steps are eighth notes.
 */
const CHASE_SCORES={
 uk:{bpm:126,lead:'sawtooth',bass:'triangle',leadGain:.017,bassGain:.014,
  melody:[62,-1,65,69,67,-1,65,62,60,-1,62,65,69,67,65,-1,62,65,70,69,65,62,60,-1,58,62,65,-1,64,62,57,-1],
  bassline:[38,38,45,38,36,36,43,36,34,34,41,34,33,33,40,33]},
 gsn:{bpm:112,lead:'square',bass:'sawtooth',leadGain:.013,bassGain:.012,
  melody:[57,-1,-1,60,62,-1,57,-1,55,-1,58,62,60,-1,-1,-1,57,60,64,-1,62,57,-1,-1,53,57,60,-1,59,-1,55,-1],
  bassline:[33,33,33,40,31,31,31,38,29,29,29,36,31,31,38,31]},
 abc:{bpm:136,lead:'square',bass:'triangle',leadGain:.014,bassGain:.015,
  melody:[67,71,74,-1,72,71,67,-1,69,72,76,74,72,-1,69,-1,67,71,74,79,76,74,71,-1,69,72,76,74,71,69,67,-1],
  bassline:[43,43,50,43,45,45,52,45,40,40,47,40,38,38,45,38]},
 btc:{bpm:158,lead:'sawtooth',bass:'square',leadGain:.013,bassGain:.011,
  melody:[64,67,71,72,71,67,64,-1,65,69,72,76,74,72,69,-1,64,67,71,76,74,71,67,64,62,65,69,72,71,69,65,-1],
  bassline:[40,40,47,40,41,41,48,41,38,38,45,38,36,36,43,36]}
};
function chaseScoreStep(mode,step,play){
 const score=CHASE_SCORES[mode]||CHASE_SCORES.uk;
 const lead=score.melody[step%score.melody.length];
 const bass=score.bassline[Math.floor(step/2)%score.bassline.length];
 const freq=n=>440*Math.pow(2,(n-69)/12);
 const seconds=60/score.bpm/2;
 if(lead>=0)play(freq(lead),seconds*.85,score.lead,score.leadGain);
 if(step%2===0)play(freq(bass),seconds*1.7,score.bass,score.bassGain);
 if(step%4===0)play(110,seconds*.16,'triangle',.009);
 if(mode==='btc'&&step%2===1)play(780,seconds*.035,'square',.004);
}
