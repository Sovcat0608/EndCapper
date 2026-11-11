// Lossless BLP2/BGRA encoding. The palette is reserved but unused (encoding 3).
// Format cross-check: Pillow BlpImagePlugin and Kanma/BLPConverter blp_internal.h.
const fs = require('node:fs');
const path = require('node:path');

function buildBLP(bgra, width, height) {
  if (![width,height].every(n=>Number.isInteger(n)&&n>0&&n<=32768&&(n&(n-1))===0) || bgra.length!==width*height*4) {
    throw Error('Expected power-of-two BGRA image');
  }
  const header=Buffer.alloc(1172), levels=[];
  header.write('BLP2');header.writeUInt32LE(1,4);
  header[8]=3;header[9]=8;header[10]=0;header[11]=1;
  header.writeUInt32LE(width,12);header.writeUInt32LE(height,16);
  // Keep unrounded, premultiplied values between reductions so tiny highlights
  // retain their coverage and transparent RGB cannot darken the filtered rings.
  let pixels=new Float64Array(bgra.length), w=width, h=height, offset=header.length;
  for(let i=0;i<bgra.length;i+=4) {
    const a=bgra[i+3];pixels[i+3]=a;
    for(let c=0;c<3;c++)pixels[i+c]=bgra[i+c]*a/255;
  }
  for(let level=0;;level++) {
    const data=Buffer.alloc(w*h*4);
    for(let i=0;i<data.length;i+=4) {
      const a=pixels[i+3];data[i+3]=Math.round(a);
      if(a>0)for(let c=0;c<3;c++)data[i+c]=Math.round(Math.min(255,pixels[i+c]*255/a));
    }
    // Two transparent texels of colour bleed prevent dark fringes during GPU
    // bilinear sampling. Alpha and every visible pixel remain unchanged.
    let known=Uint8Array.from({length:w*h},(_,i)=>data[i*4+3]>0?1:0);
    for(let pass=0;pass<2;pass++) {
      const next=known.slice(), prior=Buffer.from(data);
      for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
        const p=y*w+x;if(known[p])continue;
        const neighbors=[];
        if(x>0)neighbors.push(p-1);if(x+1<w)neighbors.push(p+1);
        if(y>0)neighbors.push(p-w);if(y+1<h)neighbors.push(p+w);
        const valid=neighbors.filter(n=>known[n]);if(!valid.length)continue;
        for(let c=0;c<3;c++)data[p*4+c]=Math.round(valid.reduce((sum,n)=>sum+prior[n*4+c],0)/valid.length);
        next[p]=1;
      }
      known=next;
    }
    header.writeUInt32LE(offset,20+level*4);header.writeUInt32LE(data.length,84+level*4);
    levels.push(data);offset+=data.length;
    if(w===1&&h===1)break;
    const nw=Math.max(1,w/2),nh=Math.max(1,h/2),reduced=new Float64Array(nw*nh*4);
    const sx=w>1?2:1,sy=h>1?2:1;
    for(let y=0;y<nh;y++)for(let x=0;x<nw;x++)for(let dy=0;dy<sy;dy++)for(let dx=0;dx<sx;dx++) {
      const from=((y*sy+dy)*w+x*sx+dx)*4,to=(y*nw+x)*4;
      for(let c=0;c<4;c++)reduced[to+c]+=pixels[from+c]/(sx*sy);
    }
    pixels=reduced;w=nw;h=nh;
  }
  return Buffer.concat([header,...levels]);
}

if(require.main===module) {
  const media=process.argv[2];if(!media)throw Error('Usage: node Build-HaloMipmaps.cjs <Media directory>');
  for(const name of ['SeraphHalo','UmbraHalo']) {
    const tga=fs.readFileSync(path.join(media,name+'.tga'));
    if(tga[0]!==0||tga[1]!==0||tga[2]!==2||tga[16]!==32||tga[17]!==40)throw Error('Expected top-left 32-bit alpha TGA');
    const w=tga.readUInt16LE(12),h=tga.readUInt16LE(14);
    const blp=buildBLP(tga.subarray(18),w,h);
    fs.writeFileSync(path.join(media,name+'.blp'),blp);
    console.log(`${name}: ${w}x${h} BLP2/BGRA, full mip chain, ${blp.length} bytes`);
  }
}
module.exports={buildBLP};
