'use strict';
/* User-owned audio is stored locally in IndexedDB, never shipped with the app. */
const ChaseAudio=(()=>{
 let dbPromise,active=null,fadeTimer=null,phase='',currentMode='';
 const open=()=>dbPromise||(dbPromise=new Promise((resolve,reject)=>{const req=indexedDB.open('chase-local-audio',1);req.onupgradeneeded=()=>req.result.createObjectStore('tracks');req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error)}));
 const key=(mode,slot)=>mode+':'+slot;
 async function save(mode,slot,file){const db=await open();return new Promise((resolve,reject)=>{const tx=db.transaction('tracks','readwrite');tx.objectStore('tracks').put(file,key(mode,slot));tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error)})}
 async function load(mode,slot){const db=await open();return new Promise((resolve,reject)=>{const tx=db.transaction('tracks');const r=tx.objectStore('tracks').get(key(mode,slot));r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error)})}
 function stop(){if(fadeTimer)clearInterval(fadeTimer);fadeTimer=null;if(active){active.pause();URL.revokeObjectURL(active.src);active=null}phase=''}
 async function play(mode,slot){stop();currentMode=mode;phase=slot;let file;try{file=await load(mode,slot)}catch(e){console.warn('Audio load failed',e);return false}if(!file||currentMode!==mode||phase!==slot)return false;const url=URL.createObjectURL(file);const el=new Audio(url);active=el;el.loop=slot==='cash'||slot==='final-team'||slot==='final-chaser'||slot==='btc-battle';el.volume=1;el.onended=()=>{if(active===el){active=null;URL.revokeObjectURL(url)}};try{await el.play();return true}catch(e){console.warn('Audio playback unavailable',e);return false}}
 function cashFade(secondsRemaining){if(phase!=='cash'||!active)return;active.volume=Math.max(0,Math.min(1,secondsRemaining/5));if(secondsRemaining<=0)stop()}
 function status(mode,slot){return load(mode,slot).then(f=>f?f.name:'Not imported').catch(()=> 'Not imported')}
 return {save,load,play,stop,cashFade,status};
})();