const assert=require('node:assert/strict'),fs=require('node:fs');
const {regions,hash,build}=require('./Build-UndercityLiquid.cjs');
for(const [name,region] of Object.entries(regions)){
  const base=fs.readFileSync(`Media/${name}.tga`),atlas=fs.readFileSync(`Media/${name}LiquidAtlas.tga`);
  assert.equal(hash(base),region.hash,'approved base remains byte-identical');
  assert.deepEqual(atlas,build(base,region),'runtime asset matches reproducible mask/animation');
  let visible=0,clear=0;
  const distinct=new Set(),changes=[];
  for(let f=0;f<64;f++){
    const cell=Buffer.alloc(128*128*4);
    for(let y=0;y<128;y++)for(let x=0;x<128;x++){
      const p=18+((Math.floor(f/8)*128+y)*1024+f%8*128+x)*4,q=(y*128+x)*4;
      atlas.copy(cell,q,p,p+4);
      const original=18+(y*1024+x)*4;
      assert.equal(atlas[p+3],atlas[original+3],'fixed silhouette, not opacity pulsing');
      if(!f){if(atlas[p+3])visible++;else clear++;}
      if(f===1&&atlas[p+3]>200)changes.push(atlas[p+1]-atlas[original+1]);
    }
    distinct.add(hash(cell));
  }
  assert(visible>500&&clear>500,'mask isolates a stream');
  assert.equal(distinct.size,64,'all 64 colour frames differ');
  assert(Math.min(...changes)<-3&&Math.max(...changes)>3,'travelling bright/dark features, not uniform pulse');
  // The wrap must be as smooth as other one-frame transitions.
  const deltas=[];
  for(let f=0;f<64;f++){
    const next=(f+1)%64;let total=0;
    for(let y=2;y<126;y++)for(let x=2;x<126;x++){
      const p=18+((Math.floor(f/8)*128+y)*1024+f%8*128+x)*4;
      const q=18+((Math.floor(next/8)*128+y)*1024+next%8*128+x)*4;
      total+=Math.abs(atlas[p+1]-atlas[q+1])*atlas[p+3]/255;
    }
    deltas.push(total);
  }
  assert(deltas[63]<Math.max(...deltas.slice(0,63))*1.1,'no loop seam');
  console.log(`PASS: ${name} liquid mask, 64 spatially varying colour frames, seamless wrap, unchanged base`);
}
