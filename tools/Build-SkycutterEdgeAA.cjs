// AA trial 3: a one-source-texel alpha filter, with every RGB byte unchanged.
const fs=require('node:fs');
const path=require('node:path');

function softenAlpha(bgra,width,height) {
  if(!Number.isInteger(width)||!Number.isInteger(height)||width<1||height<1||bgra.length!==width*height*4)
    throw Error('Expected BGRA pixels matching the dimensions');
  const result=Buffer.from(bgra),weights=[1,2,1];
  for(let y=0;y<height;y++)for(let x=0;x<width;x++) {
    let alpha=0,minAlpha=255;
    for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++) {
      const sx=Math.max(0,Math.min(width-1,x+dx)),sy=Math.max(0,Math.min(height-1,y+dy));
      const a=bgra[(sy*width+sx)*4+3];
      minAlpha=Math.min(minAlpha,a);
      alpha+=a*weights[dx+1]*weights[dy+1];
    }
    // This source's solid paint is usually alpha252/253, not255. Preserve its
    // interior opacity variation as well as all RGB; filter only near transparency.
    const p=(y*width+x)*4;
    // Do not reveal empty black RGB outside the source's existing colour bleed.
    const emptyBlack=bgra[p+3]===0 && bgra[p]===0 && bgra[p+1]===0 && bgra[p+2]===0;
    if(minAlpha<240 && !emptyBlack)result[p+3]=Math.round(alpha/16);
  }
  return result;
}

if(require.main===module) {
  const root=path.join(__dirname,'..');
  const tga=fs.readFileSync(path.join(root,'Media/SkycutterBoatStaticProbe.tga'));
  if(tga.length!==18+1024*1024*4 || tga[2]!==2 || tga[16]!==32 || tga[17]!==40 ||
      tga.readUInt16LE(12)!==1024 || tga.readUInt16LE(14)!==1024)throw Error('Expected baseline top-origin BGRA TGA');
  const out=Buffer.concat([tga.subarray(0,18),softenAlpha(tga.subarray(18),1024,1024)]);
  fs.writeFileSync(path.join(root,'Media/SkycutterBoatEdgeAA.tga'),out);
  console.log('SkycutterBoatEdgeAA: original RGB/header/dimensions, localized 3x3 binomial alpha smoothing, no mipmaps');
}
module.exports={softenAlpha};
