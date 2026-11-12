// Independent size-specific TGA assets derived only from the sharp baseline.
const fs=require('node:fs'),path=require('node:path');
const {buildBLP}=require('./Build-HaloMipmaps.cjs');
const widths=[192,288,384,480,576,768,960];
const pow2=n=>2**Math.ceil(Math.log2(n));
function weights(source,target) {
  const scale=source/target,sinc=x=>Math.abs(x)<1e-8?1:Math.sin(Math.PI*x)/(Math.PI*x);
  return Array.from({length:target},(_,x)=>{
    const centre=(x+.5)*scale-.5,taps=[];let total=0;
    for(let i=Math.ceil(centre-2*scale);i<=Math.floor(centre+2*scale);i++) {
      const d=(i-centre)/scale,w=Math.abs(d)<2?sinc(d)*sinc(d/2):0;
      taps.push([Math.max(0,Math.min(source-1,i)),w]);total+=w;
    }
    return taps.map(([i,w])=>[i,w/total]);
  });
}
function buildSize(bgra,sourceW,sourceH,w,h) {
  if(bgra.length!==sourceW*sourceH*4 || ![sourceW,sourceH,w,h].every(n=>Number.isInteger(n)&&n>0) || w>sourceW || h>sourceH)
    throw Error('Expected BGRA dimensions and downsampling sizes');
  const wx=weights(sourceW,w),wy=weights(sourceH,h),horizontal=new Float64Array(sourceH*w*4);
  for(let y=0;y<sourceH;y++)for(let x=0;x<w;x++) {
    const p=(y*w+x)*4;
    for(const [sx,weight] of wx[x]) {
      const q=(y*sourceW+sx)*4,a=bgra[q+3];
      for(let c=0;c<3;c++)horizontal[p+c]+=bgra[q+c]*a/255*weight;
      horizontal[p+3]+=a*weight;
    }
  }
  const tw=pow2(w),th=pow2(h),pixels=Buffer.alloc(tw*th*4);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
    const sums=[0,0,0,0],p=(y*tw+x)*4;
    for(const [sy,weight] of wy[y])for(let c=0;c<4;c++)sums[c]+=horizontal[(sy*w+x)*4+c]*weight;
    pixels[p+3]=Math.round(Math.max(0,Math.min(255,sums[3])));
    if(pixels[p+3] && sums[3]>0)for(let c=0;c<3;c++)pixels[p+c]=Math.round(Math.max(0,Math.min(255,sums[c]*255/sums[3])));
  }
  // Reuse transparent RGB bleed; discard all generated mips and export TGA.
  const encoded=buildBLP(pixels,tw,th),offset=encoded.readUInt32LE(20);
  const header=Buffer.alloc(18);header[2]=2;header[16]=32;header[17]=40;
  header.writeUInt16LE(tw,12);header.writeUInt16LE(th,14);
  return Buffer.concat([header,encoded.subarray(offset,offset+pixels.length)]);
}
if(require.main===module) {
  const root=path.join(__dirname,'..'),base=fs.readFileSync(path.join(root,'Media/SkycutterBoatStaticProbe.tga'));
  if(base.length!==18+1024*1024*4 || base[2]!==2 || base[16]!==32 || base[17]!==40 ||
      base.readUInt16LE(12)!==1024 || base.readUInt16LE(14)!==1024)throw Error('Expected sharp baseline TGA');
  for(const w of widths) {
    const h=w*2/3,tga=buildSize(base.subarray(18),1024,1024,w,h);
    fs.writeFileSync(path.join(root,`Media/SkycutterBoatSize${w}.tga`),tga);
    console.log(`Skycutter size ${w}x${h}, padded ${tga.readUInt16LE(12)}x${tga.readUInt16LE(14)}, no runtime mipmaps`);
  }
}
module.exports={buildSize,widths};
