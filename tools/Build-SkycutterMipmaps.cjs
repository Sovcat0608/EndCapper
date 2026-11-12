const fs=require('node:fs');
const path=require('node:path');
const {buildBLP}=require('./Build-HaloMipmaps.cjs');

// Scale-aware Lanczos2, evaluated directly from level 0 for every display mip.
// Filter premultiplied colour and coverage together to exclude invisible RGB.
function resampleBoat(bgra, width, size) {
  const scale=width/size, weights=[];
  const sinc=x=>Math.abs(x)<1e-8?1:Math.sin(Math.PI*x)/(Math.PI*x);
  for(let x=0;x<size;x++) {
    const centre=(x+0.5)*scale-0.5, taps=[];
    let sum=0;
    for(let i=Math.ceil(centre-2*scale);i<=Math.floor(centre+2*scale);i++) {
      const distance=(i-centre)/scale;
      const weight=Math.abs(distance)<2?sinc(distance)*sinc(distance/2):0;
      taps.push([Math.max(0,Math.min(width-1,i)),weight]);sum+=weight;
    }
    weights.push(taps.map(([i,w])=>[i,w/sum]));
  }
  const horizontal=new Float64Array(width*size*4);
  for(let y=0;y<width;y++)for(let x=0;x<size;x++) {
    const dst=(y*size+x)*4;
    for(const [sx,w] of weights[x]) {
      const src=(y*width+sx)*4,a=bgra[src+3];
      for(let c=0;c<3;c++)horizontal[dst+c]+=bgra[src+c]*a/255*w;
      horizontal[dst+3]+=a*w;
    }
  }
  const result=new Float64Array(size*size*4);
  for(let y=0;y<size;y++)for(let x=0;x<size;x++) {
    const dst=(y*size+x)*4;
    for(const [sy,w] of weights[y]) {
      const src=(sy*size+x)*4;
      for(let c=0;c<4;c++)result[dst+c]+=horizontal[src+c]*w;
    }
  }
  return result;
}

function buildBoatBLP(bgra, width=1024) {
  const blp=buildBLP(bgra,width,width);
  const result=Buffer.from(blp);
  for(let level=1;level<=6 && (width>>level)>=16;level++) {
    const size=width>>level;
    const offset=blp.readUInt32LE(20+level*4);
    const filtered=resampleBoat(bgra,width,size);
    for(let y=1;y<size-1;y++)for(let x=1;x<size-1;x++) {
      const local=(y*size+x)*4,p=offset+local;
      let minAlpha=255;
      const low=[255,255,255],high=[0,0,0];
      for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++) {
        const q=offset+((y+dy)*size+x+dx)*4;
        minAlpha=Math.min(minAlpha,blp[q+3]);
        for(let c=0;c<3;c++){low[c]=Math.min(low[c],blp[q+c]);high[c]=Math.max(high[c],blp[q+c]);}
      }
      if(minAlpha<224 || filtered[local+3]<=0)continue;
      // Retain proven box-filtered alpha and soft contours. Fade colour changes
      // near coverage edges and clamp ringing to the local colour range.
      const blend=(minAlpha-224)/31;
      for(let c=0;c<3;c++) {
        const colour=Math.max(low[c],Math.min(high[c],filtered[local+c]*255/filtered[local+3]));
        result[p+c]=Math.round(blp[p+c]+(colour-blp[p+c])*blend);
      }
    }
  }
  return result;
}

if(require.main===module) {
const input=process.argv[2];
if(!input)throw Error('Usage: node Build-SkycutterMipmaps.cjs <boat source TGA>');
const tga=fs.readFileSync(input);
if(tga.length!==18+1024*1024*4||tga[2]!==2||tga[16]!==32||tga[17]!==40||tga.readUInt16LE(12)!==1024||tga.readUInt16LE(14)!==1024)throw Error('Expected 1024-square top-origin BGRA boat');
const blp=buildBoatBLP(tga.subarray(18),1024);
fs.writeFileSync(path.join(__dirname,'../Media/SkycutterBoat.blp'),blp);
// Format-comparison trial: export the identical full-resolution BGRA payload,
// including transparent-edge colour bleed, without any authored mip levels.
const header=Buffer.alloc(18);
header[2]=2;header[16]=32;header[17]=40;
header.writeUInt16LE(1024,12);header.writeUInt16LE(1024,14);
const start=blp.readUInt32LE(20),length=blp.readUInt32LE(84);
const tgaOutput=Buffer.concat([header,blp.subarray(start,start+length)]);
fs.writeFileSync(path.join(__dirname,'../Media/SkycutterBoat.tga'),tgaOutput);
// Fresh basename prevents legacy same-stem BLP lookup during the static comparison.
fs.writeFileSync(path.join(__dirname,'../Media/SkycutterBoatStaticProbe.tga'),tgaOutput);
console.log('SkycutterBoat: 1024-square BGRA BLP2, direct-source Lanczos2 colour mips with preserved alpha/soft edges');
console.log('SkycutterBoat TGA trial: identical level-0 pixels, uncompressed 32-bit BGRA with alpha');
}
module.exports={buildBoatBLP,resampleBoat};
