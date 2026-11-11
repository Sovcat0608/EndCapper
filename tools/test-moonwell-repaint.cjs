// Asset registration tests against the shipped textures, independent of mocks.
const fs=require('node:fs');
const read=name=>fs.readFileSync(`Media/${name}.tga`);
const layers=['Glyphs','Moon','Water','Bounce'].map(n=>read('Moonwell'+n));
const base=read('Moonwell');
const a=(t,x,y)=>t[21+(y*256+x)*4];
const sample=(t,x,y)=>a(t,Math.floor(x*256),Math.floor(y*256));
// The repainted pool has a continuous luminous centre and a strong rim;
// reflected light remains outside that surface.
for(const [x,y] of [[.36,.61],[.40,.62],[.43,.64],[.39,.68]]){
 if(sample(layers[2],x,y)<100)throw Error('Missing repaint water emission at '+[x,y]);
 if(sample(layers[3],x,y)!==0)throw Error('Reflected glow intrudes on water at '+[x,y]);
}
for(const [kind,x0,y0,x1,y1] of [[0,.12,.4,.17,.55],[0,.18,.72,.35,.89],[0,.58,.76,.78,.89],[0,.27,.30,.47,.37],[1,.14,.55,.24,.70]]){
 let energy=0;for(let y=Math.floor(y0*256);y<y1*256;y++)for(let x=Math.floor(x0*256);x<x1*256;x++)energy+=a(layers[kind],x,y);
 if(energy<500)throw Error('Missing repainted glyph/moon region '+[kind,x0,y0]);
}
let reflected=0,distinctWaterColours=new Set();
for(let y=0;y<256;y++)for(let x=0;x<256;x++){
 const p=18+(y*256+x)*4;
 if(layers[2][p+3]&&layers[3][p+3])throw Error('Water and reflected-light masks overlap');
 if(layers[3][p+3])reflected++;
 if(layers[2][p+3]>100)distinctWaterColours.add(layers[2].subarray(p,p+3).toString('hex'));
 // All emission planes are restricted to opaque artwork; allow the 2x
 // resampling footprint when comparing 256 masks with the 512 base.
 for(const t of layers)if(t[p+3]){
  let covered=false;
  for(let dy=0;dy<2;dy++)for(let dx=0;dx<2;dx++)if(base[21+((y*2+dy)*512+x*2+dx)*4]>=200)covered=true;
  if(!covered)throw Error('Emission outside repainted artwork at '+[x,y]);
 }
}
if(reflected<100||distinctWaterColours.size<100)throw Error('Missing reflected glow or water ripple colour detail');
const clip=fs.readFileSync('Clipping.lua','utf8');
for(const [name,id] of [['VerdantRoot','verdantRoot'],['Moonwell','moonwell']]){
 const texture=read(name);let last=0;
 for(let y=0;y<512;y++){let count=0;for(let x=0;x<512;x++)if(texture[21+(y*512+x)*4]>=200)count++;if(count>=6)last=y;}
 const match=clip.match(new RegExp(id+'=(\\d+)/512'));
 if(!match||Number(match[1])!==last+1)throw Error('Clipping baseline differs from repainted base: '+name);
}
console.log('Repaint PASS: glyph/moon regions, filled water centre, disjoint reflection, preserved ripple colours, opaque-surface registration and both clipping baselines');
