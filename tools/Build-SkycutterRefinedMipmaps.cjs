// AA trial 2: direct-source Lanczos2 for both colour and alpha, including edges.
// Keep the prior trial and sharp TGA intact. No sharpening pass or runtime bias.
const fs=require('node:fs');
const path=require('node:path');
const {buildBLP}=require('./Build-HaloMipmaps.cjs');
const {resampleBoat}=require('./Build-SkycutterMipmaps.cjs');

function buildRefinedBLP(bgra,width=1024) {
  const box=buildBLP(bgra,width,width),result=Buffer.from(box);
  // Preserve every source byte, including the baseline's transparent RGB bleed.
  bgra.copy(result,result.readUInt32LE(20));
  for(let level=1;(width>>level)>=16;level++) {
    const size=width>>level,offset=box.readUInt32LE(20+4*level);
    const filtered=resampleBoat(bgra,width,size),pixels=Buffer.alloc(size*size*4);
    for(let y=0;y<size;y++)for(let x=0;x<size;x++) {
      const p=(y*size+x)*4,low=[255,255,255,255],high=[0,0,0,0];
      // Bound negative-lobe ringing by the local area-filtered neighbourhood.
      for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++) {
        const q=offset+(Math.max(0,Math.min(size-1,y+dy))*size+Math.max(0,Math.min(size-1,x+dx)))*4;
        low[3]=Math.min(low[3],box[q+3]);high[3]=Math.max(high[3],box[q+3]);
        if(box[q+3])for(let c=0;c<3;c++) {
          low[c]=Math.min(low[c],box[q+c]);high[c]=Math.max(high[c],box[q+c]);
        }
      }
      const a=filtered[p+3];
      pixels[p+3]=Math.round(Math.max(low[3],Math.min(high[3],a)));
      if(pixels[p+3] && a>0)for(let c=0;c<3;c++) {
        pixels[p+c]=Math.round(Math.max(low[c],Math.min(high[c],filtered[p+c]*255/a)));
      }
    }
    // Reuse the established transparent-colour bleed, taking only its level 0.
    const encoded=buildBLP(pixels,size,size),start=encoded.readUInt32LE(20);
    encoded.copy(result,offset,start,start+pixels.length);
  }
  return result;
}

if(require.main===module) {
  const root=path.join(__dirname,'..'),tga=fs.readFileSync(path.join(root,'Media/SkycutterBoatStaticProbe.tga'));
  if(tga.length!==18+1024*1024*4 || tga[2]!==2 || tga[16]!==32 || tga[17]!==40 ||
      tga.readUInt16LE(12)!==1024 || tga.readUInt16LE(14)!==1024)throw Error('Expected baseline top-origin BGRA TGA');
  fs.writeFileSync(path.join(root,'Media/SkycutterBoatRefined.blp'),buildRefinedBLP(tga.subarray(18)));
  console.log('SkycutterBoatRefined: exact level 0, bounded direct-source colour/alpha Lanczos2 mips, unchanged tiny tails');
}
module.exports={buildRefinedBLP};
