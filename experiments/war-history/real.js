// Earth's real war record (Brecke Conflict Catalog, 1400-2000) on your engine, against a peaceful twin.
// Usage: node real.js [display] [update] [gravity on|off] [years after 2000] [real|nudge] [seed]
//   nudge = control: no wars, one cell of one pixel flipped in 1400.
const {Engine,N,S,H}=require("../../origin/viewer/engine.js");
const {EARTH_WARS}=require("../../origin/viewer/earth-wars.js");
const [display,update,g]=[process.argv[2]||"one_cell",process.argv[3]||"sync",(process.argv[4]||"on")==="on"];
const AFTER=+(process.argv[5]||0),MODE=process.argv[6]||"real",SEED=BigInt(process.argv[7]||20261110);
class E extends Engine{ready(i){return super.ready(i)||(this.forced!=null&&this.forced[i]===1)}}
const A=new E({display,update,core:0,gravity:g,seed:SEED});for(let t=0;t<150;t++)A.tick();
const B=new E(A.cfg);for(const k of["pat","rf","cs","carrier"])B[k].set(A[k]);
// same placement as war.html: regions 1-12 on a 3x2x2 grid, jittered; -9 (global) at the centre
function place(w,k){if(w[2]<0)return[H,H,H];const gr=w[2]-1,h=(k*2654435761)>>>0;const j=n=>((h>>>(n*8))&255)/255*14-7;
  return[(8+16*(gr%3)+j(0)+S)%S|0,(12+24*((gr/3|0)%2)+j(1)+S)%S|0,(12+24*((gr/6|0)%2)+j(2)+S)%S|0]}
if(MODE==="nudge")A.pat[(H*S+H)*S+H]^=1;
const forced=new Uint8Array(N),touched=new Uint8Array(N);let wars=[],next=0;
const agr=e=>{let s=0,n=0;for(let i=0;i<N;i+=11){s+=e.agreement(i);n++}return s/n};
console.log("year  div%  agrWar agrPeace flashWar flashPeace flashWar(outside wars) activeWars %atWar %everTouched");
for(let yr=1400;yr<=2000+AFTER;yr++){
  while(MODE==="real"&&next<EARTH_WARS.length&&EARTH_WARS[next][0]<=yr){const w=EARTH_WARS[next++],c=place(w,next);wars.push({c,r:w[3],end:yr+w[1]})}
  wars=wars.filter(w=>w.end>yr);forced.fill(0);
  for(const w of wars){const r=Math.ceil(w.r),[x,y,z]=w.c;for(let dz=-r;dz<=r;dz++)for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++){
    if(dx*dx+dy*dy+dz*dz>w.r*w.r)continue;const i=(((z+dz+S)%S)*S+((y+dy+S)%S))*S+((x+dx+S)%S);forced[i]=1;touched[i]=1}}
  A.forced=forced;const fa=A.tick(),fb=B.tick();
  if(yr%50===0){let d=0,at=0,tc=0,fo=0,no=0;for(let i=0;i<N;i++){if(A.pat[i]!==B.pat[i])d++;at+=forced[i];tc+=touched[i];if(!forced[i]){no++;fo+=A.fired[i]}}
    console.log(yr,(100*d/N).toFixed(1).padStart(5),agr(A).toFixed(3),agr(B).toFixed(3),(fa/N).toFixed(3),(fb/N).toFixed(3),(fo/no).toFixed(3).padStart(10),String(wars.length).padStart(12),(100*at/N).toFixed(1).padStart(7),(100*tc/N).toFixed(1).padStart(8))}
}
