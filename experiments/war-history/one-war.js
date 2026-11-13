const {Engine,N,RAD}=require("../../origin/viewer/engine.js");
const [display,update,g,kind,AFTER]=[process.argv[2]||"one_cell",process.argv[3]||"sync",(process.argv[4]||"on")==="on",process.argv[5]||"war",+(process.argv[6]||1000)];
class E extends Engine{ready(i){return super.ready(i)||(this.forced!=null&&this.forced[i]===1)}}
const A=new E({display,update,core:0,gravity:g});for(let t=0;t<150;t++)A.tick();
const B=new E(A.cfg);for(const k of["pat","rf","cs","carrier"])B[k].set(A[k]);
const reg=new Uint8Array(N);for(let i=0;i<N;i++)if(RAD[i]<=8)reg[i]=1;
const WAR=kind==="war"?30:0;
if(kind==="nudge")A.pat[(24*48+24)*48+24]^=1; // one cell of one pixel
const out=[];
for(let t=0;t<WAR+AFTER;t++){A.forced=t<WAR?reg:null;A.tick();B.tick();
  if((t+1)%100===0){let d=0;for(let i=0;i<N;i++)if(A.pat[i]!==B.pat[i])d++;out.push((100*d/N).toFixed(1))}}
console.log(display,update,g?"grav":"nograv",kind,out.join(" "));
