// Chemical precompression on origin's lattice (unchanged engine; outside conditions only).
// Usage: node run.js [display] [update] [gravity on|off] [cage none|cage|random] [T jostle chance] [seed] [ticks]
//   cage:   1 site in 8 (x,y,z all even) held at pattern 111 every tick
//   random: the same number of held sites at random positions (control)
//   T:      each tick, each free pixel has chance T of one random cell flipping
// Prints: free-pixel agreement (free-free bonds only) and flash rate, averaged over the last third.
const {Engine,N,S}=require("../../origin/viewer/engine.js");
const a=process.argv;
const display=a[2]||"one_cell",update=a[3]||"sync",grav=(a[4]||"off")==="on",cage=a[5]||"none",T=+(a[6]||0),seed=BigInt(a[7]||1),TICKS=+(a[8]||600);
const e=new Engine({display,update,core:0,gravity:grav,seed});
let rs=Number(seed%4294967295n)^0x9e3779b9;const rnd=()=>{rs^=rs<<13;rs^=rs>>>17;rs^=rs<<5;return (rs>>>0)/4294967296};
const held=new Uint8Array(N);
if(cage==="cage")for(let i=0;i<N;i++){const x=i%S,y=(i/S|0)%S,z=i/(S*S)|0;if(x%2===0&&y%2===0&&z%2===0)held[i]=1}
if(cage==="random"){let k=0;const want=(S/2)**3;while(k<want){const i=rnd()*N|0;if(!held[i]){held[i]=1;k++}}}
const NB=[];for(let i=0;i<N;i++){const x=i%S,y=(i/S|0)%S,z=i/(S*S)|0,id=(a,b,c)=>(((c+S)%S)*S+((b+S)%S))*S+((a+S)%S);NB.push([id(x+1,y,z),id(x-1,y,z),id(x,y+1,z),id(x,y-1,z),id(x,y,z+1),id(x,y,z-1)])}
const pin=()=>{for(let i=0;i<N;i++)if(held[i])e.pat[i]=7};
pin();
let agrS=0,flS=0,n=0;
for(let t=0;t<TICKS;t++){
  if(T>0)for(let i=0;i<N;i++)if(!held[i]&&rnd()<T)e.pat[i]^=1<<(rnd()*3|0);
  const f=e.tick();pin();
  if(t>=TICKS*2/3){let m=0,b=0,fl=0,fr=0;
    for(let i=0;i<N;i+=3){if(held[i])continue;fr++;fl+=e.fired[i];for(const j of NB[i]){if(held[j])continue;const x=e.pat[i]^e.pat[j];m+=3-((x&1)+((x>>1)&1)+((x>>2)&1));b++}}
    agrS+=m/(3*b);flS+=fl/fr;n++}
}
console.log([display,update,grav?"on":"off",cage,T,seed,(agrS/n).toFixed(4),(flS/n).toFixed(4)].join("\t"));
