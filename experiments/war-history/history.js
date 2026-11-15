const {Engine,N,S}=require("../../origin/viewer/engine.js");
const [display,update,g]=[process.argv[2]||"one_cell",process.argv[3]||"sync",(process.argv[4]||"on")==="on"];
const YEARS=+(process.argv[5]||3000), RATE=+(process.argv[6]||1.5);
class E extends Engine{ready(i){return super.ready(i)||(this.forced!=null&&this.forced[i]===1)}}
const A=new E({display,update,core:0,gravity:g});for(let t=0;t<150;t++)A.tick();
const B=new E(A.cfg);for(const k of["pat","rf","cs","carrier"])B[k].set(A[k]);
let rs=987654321;const rnd=()=>((rs=(Math.imul(rs,1103515245)+12345)>>>0)/4294967296);
const wars=[];const forced=new Uint8Array(N);let started=0,warYears=0,touched=new Uint8Array(N);
const agr=e=>{let s=0,n=0;for(let i=0;i<N;i+=11){s+=e.agreement(i);n++}return s/n};
const zero=e=>{let z=0;for(let i=0;i<N;i++)if(e.pat[i]===0)z++;return z/N};
console.log("year div% agrWar agrPeace flashWar flashPeace activeWars %atWar %everTouched");
for(let y=1;y<=YEARS;y++){
  let k=0,L=Math.exp(-RATE),p=1;do{k++;p*=rnd()}while(p>L);k--;  // Poisson new wars
  for(let w=0;w<k;w++){wars.push({x:rnd()*S|0,y:rnd()*S|0,z:rnd()*S|0,r:3+rnd()*5,end:y+1+(rnd()*10|0)});started++}
  for(let i=wars.length-1;i>=0;i--)if(wars[i].end<=y)wars.splice(i,1);
  forced.fill(0);
  for(const w of wars){const r=Math.ceil(w.r);for(let dz=-r;dz<=r;dz++)for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++){
    if(dx*dx+dy*dy+dz*dz>w.r*w.r)continue;const i=(((w.z+dz+S)%S)*S+((w.y+dy+S)%S))*S+((w.x+dx+S)%S);forced[i]=1;touched[i]=1}}
  let at=0;for(let i=0;i<N;i++)at+=forced[i];
  A.forced=forced;const fa=A.tick(),fb=B.tick();
  if(y%100===0){let d=0,tc=0;for(let i=0;i<N;i++){if(A.pat[i]!==B.pat[i])d++;tc+=touched[i]}
    console.log(y,(100*d/N).toFixed(1),agr(A).toFixed(3),agr(B).toFixed(3),(fa/N).toFixed(3),(fb/N).toFixed(3),wars.length,(100*at/N).toFixed(1),(100*tc/N).toFixed(1))}
}
console.log("wars started",started);
