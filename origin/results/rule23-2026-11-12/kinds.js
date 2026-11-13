// Rule 23 per-kind measures. Usage: node kinds.js display update seed ticks
const {Engine,N}=require("../../viewer/engine.js");
const [d,u,s,T]=[process.argv[2],process.argv[3],BigInt(process.argv[4]),+process.argv[5]];
const e=new Engine({display:d,update:u,core:8,channels:true,seed:s});
const pop=[0,0,0,0],fl=[0,0,0,0];let n=0;
for(let t=0;t<T;t++){e.tick();if(t>=T*2/3){n++;for(let i=0;i<N;i++){const p=e.pat[i],k=(p&1)+((p>>1)&1)+((p>>2)&1);pop[k]++;fl[k]+=e.fired[i]}}}
const kinds=["neutrino","down","up","electron"],out=[];
for(let k=0;k<4;k++){const a=[0,1,2].map(c=>e.absorbed[k*3+c]),tot=a[0]+a[1]+a[2];
  out.push([d,u,String(s),kinds[k],(pop[k]/(n*N)).toFixed(4),pop[k]?(fl[k]/pop[k]).toFixed(4):"nan",tot,...a.map(v=>tot?(v/tot).toFixed(4):"nan")].join("\t"))}
console.log(out.join("\n"));
