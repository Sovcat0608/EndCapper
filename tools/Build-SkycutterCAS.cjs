// Offline adaptation of AMD CAS sharpen-only, CAS_SLOW + CAS_GO_SLOWER,
// without CAS_BETTER_DIAGONALS. See THIRD-PARTY-CAS.txt for MIT notice/source.
// EndCapper additions: sRGB conversion, alpha-neighbourhood protection and blend.
const fs=require('node:fs'),path=require('node:path');
const {widths}=require('./Build-SkycutterSizes.cjs');
const sharpness=1.0,blend=0.65;
const clamp=x=>Math.max(0,Math.min(1,x));
const linear=Array.from({length:256},(_,i)=>{const x=i/255;return x<=0.04045?x/12.92:((x+0.055)/1.055)**2.4;});
const encode=x=>Math.round(255*(x<=0.0031308?12.92*x:1.055*x**(1/2.4)-0.055));
function sharpen(tga,w,h,amount=blend) {
  const tw=tga.readUInt16LE(12),th=tga.readUInt16LE(14);
  if(tga[2]!==2||tga[16]!==32||tga[17]!==40||tga.length!==18+tw*th*4||
      ![w,h].every(Number.isInteger)||w<1||h<1||w>tw||h>th||!Number.isFinite(amount)||amount<0||amount>1)
    throw Error('Invalid CAS TGA/content dimensions or blend');
  const out=Buffer.from(tga),peak=-1/(8-3*sharpness);
  const at=(x,y)=>18+(Math.max(0,Math.min(h-1,y))*tw+Math.max(0,Math.min(w-1,x)))*4;
  for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
    const e=at(x,y),b=at(x,y-1),d=at(x-1,y),f=at(x+1,y),n=at(x,y+1);
    // Protect the whole 3x3 transparency boundary, not just the centre alpha.
    let alpha=255;
    for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++)alpha=Math.min(alpha,tga[at(x+dx,y+dy)+3]);
    const t=clamp((alpha-224)/31),mix=amount*t*t*(3-2*t);
    if(!mix)continue;
    for(let c=0;c<3;c++) {
      const centre=linear[tga[e+c]],v=[b,d,f,n].map(p=>linear[tga[p+c]]);
      const lo=Math.min(centre,...v),hi=Math.max(centre,...v);
      const weight=hi>0?Math.sqrt(clamp(Math.min(lo,1-hi)/hi))*peak:0;
      const cas=clamp((centre+weight*(v[0]+v[1]+v[2]+v[3]))/(1+4*weight));
      out[e+c]=encode(clamp(centre+(cas-centre)*mix));
    }
  }
  return out;
}
if(require.main===module) {
  const media=path.join(__dirname,'../Media');
  for(const w of widths) {
    const input=fs.readFileSync(path.join(media,`SkycutterBoatSize${w}.tga`));
    fs.writeFileSync(path.join(media,`SkycutterBoatCASSize${w}.tga`),sharpen(input,w,w*2/3));
    console.log(`Babe + CAS: ${w}x${w*2/3}, sharpness ${sharpness}, blend ${blend}, alpha preserved`);
  }
}
module.exports={sharpen,sharpness,blend};
