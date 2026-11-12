const assert=require('node:assert/strict');
const fs=require('node:fs');
const {buildBLP}=require('./Build-HaloMipmaps.cjs');
// One opaque red texel + three transparent blue texels must reduce to 25%
// red coverage, without bleeding the invisible blue into the visible ring.
const sample=buildBLP(Buffer.from([0,0,255,255,255,0,0,0,255,0,0,0,255,0,0,0]),2,2);
assert.deepEqual([...sample.subarray(8,12)],[3,8,2,1], 'Raw BGRA must request ARGB8888 upload, not DXT1');
assert.deepEqual([...sample.subarray(sample.readUInt32LE(24))],[0,0,255,64]);
assert.throws(()=>buildBLP(Buffer.alloc(3*2*4),3,2),/power-of-two/);
const external=JSON.parse(fs.readFileSync('tools/external-media.json','utf8'));
for(const [name,width] of [['SkycutterBoatRefined',1024],['SkycutterBoat',1024],['SeraphHalo',512],['UmbraHalo',512],['ArcaneCrystal',256],['ArcaneSigil',256],['SoulboundCrystal',256],['SoulboundCrystalEmission',256]]) {
  const mipCount=Math.log2(width)+1;
  const rel=`Media/${name}.blp`,file=fs.existsSync(rel)?rel:external[rel],b=fs.readFileSync(file);
  assert.equal(b.toString('ascii',0,4),'BLP2');
  assert.equal(b.readUInt32LE(4),1);
  assert.deepEqual([...b.subarray(8,12)],[3,8,2,1]);
  assert.equal(b.readUInt32LE(12),width);assert.equal(b.readUInt32LE(16),width);
  let end=1172,baseAlpha=0;
  const top=b.readUInt32LE(20);
  for(let i=top+3;i<top+width*width*4;i+=4)baseAlpha+=b[i];
  for(let level=0;level<16;level++) {
    const offset=b.readUInt32LE(20+level*4),length=b.readUInt32LE(84+level*4);
    if(level>=mipCount){assert.equal(offset,0);assert.equal(length,0);continue;}
    const size=width>>level;
    assert.equal(offset,end);assert.equal(length,size*size*4);assert.ok(offset+length<=b.length);
    let alpha=0;for(let i=offset+3;i<offset+length;i+=4)alpha+=b[i];
    assert.ok(Math.abs(alpha/(size*size)-baseAlpha/(width*width))<=0.5,'Mips must preserve average alpha coverage');
    if(name.endsWith('Halo')&&size>=32) {
      for(let y=Math.floor(size*0.45);y<Math.floor(size*0.55);y++)for(let x=Math.floor(size*0.45);x<Math.floor(size*0.55);x++) {
        assert.ok(b[offset+(y*size+x)*4+3]<=5,`Open halo centre: ${name}, mip ${level}`);
      }
    }
    end+=length;
  }
  assert.equal(end,b.length);
  let clear=0,visible=0,solid=0;
  for(let i=top+3;i<top+width*width*4;i+=4){if(b[i]===0)clear++;else visible++;if(b[i]===255)solid++;}
  assert.ok(clear>0&&visible>0);
  if(name.endsWith('Halo'))assert.ok(clear>1000&&solid>1000);
  // Original source TGAs remain for rebuilds, but are not required to test an
  // extracted package. Where available, prove every visible level-0 pixel and
  // all alpha values are unchanged by encoding/transparent-edge colour bleed.
  const localSource=`Media/${name}.tga`;
  const source=fs.existsSync(localSource)?localSource:file.replace(/\.blp$/,'.tga');
  if(fs.existsSync(source)) {
    const tga=fs.readFileSync(source);
    for(let i=0;i<width*width*4;i+=4) {
      assert.equal(b[top+i+3],tga[18+i+3]);
      if(tga[18+i+3])assert.ok(b.subarray(top+i,top+i+3).equals(tga.subarray(18+i,18+i+3)));
    }
  }
  console.log(`Mipmapped texture PASS: ${name}, ${mipCount} BGRA mip levels, alpha coverage, original visible pixels`);
}
