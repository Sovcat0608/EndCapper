const assert=require('node:assert/strict');
const fs=require('node:fs');
const {buildBLP}=require('./Build-HaloMipmaps.cjs');
const {buildBoatBLP}=require('./Build-SkycutterMipmaps.cjs');
const b=fs.readFileSync('Media/SkycutterBoat.blp');
// Level 0 is preserved: reconstruct the original chain from that source.
const base=b.subarray(b.readUInt32LE(20),b.readUInt32LE(20)+b.readUInt32LE(84));
const tga=fs.readFileSync('Media/SkycutterBoat.tga');
assert.deepEqual(fs.readFileSync('Media/SkycutterBoatStaticProbe.tga'),tga,'Fresh filename must preserve every TGA byte');
assert.ok(!fs.existsSync('Media/SkycutterBoatStaticProbe.blp'),'Probe must not have a same-stem BLP');
assert.equal(tga.length,18+base.length);
assert.equal(tga[2],2);assert.equal(tga[16],32);assert.equal(tga[17],40);
assert.equal(tga.readUInt16LE(12),1024);assert.equal(tga.readUInt16LE(14),1024);
assert.deepEqual(tga.subarray(18),base,'TGA comparison must preserve every full-resolution BGRA pixel');
console.log('Skycutter TGA PASS: exact BLP level-0 pixels, 1024-square, 32-bit alpha and top-left orientation');
const original=buildBLP(base,1024,1024);
assert.deepEqual(b,buildBoatBLP(base),'Installed asset must reproduce from its original level 0');
assert.deepEqual(b.subarray(0,1172),original.subarray(0,1172));
let changes=0;
for(let level=0;level<=10;level++) {
  const size=1024>>level,offset=b.readUInt32LE(20+level*4);
  for(let y=0;y<size;y++)for(let x=0;x<size;x++) {
    const p=offset+(y*size+x)*4;
    assert.equal(b[p+3],original[p+3],'All alpha must remain identical');
    let protectedPixel=level===0||level>6||x===0||y===0||x===size-1||y===size-1;
    if(!protectedPixel)for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++) {
      if(original[offset+((y+dy)*size+x+dx)*4+3]<224)protectedPixel=true;
    }
    for(let c=0;c<3;c++) {
      if(protectedPixel)assert.equal(b[p+c],original[p+c],'Source, soft edges and tiny mip tails must remain unchanged');
      if(!protectedPixel) {
        let low=255,high=0;
        for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++) {
          const value=original[offset+((y+dy)*size+x+dx)*4+c];
          low=Math.min(low,value);high=Math.max(high,value);
        }
        assert.ok(b[p+c]>=low && b[p+c]<=high,'Resampling must not introduce ringing outside the local colour range');
      }
      if(b[p+c]!==original[p+c])changes++;
    }
  }
}
assert.ok(changes>1000,'Trial must make a measurable interior contrast change');
// Constant colour must stay constant; invisible colour must not tint the mips.
const constant=Buffer.alloc(64*64*4);
for(let i=0;i<constant.length;i+=4)constant.set([35,125,210,255],i);
assert.deepEqual(buildBoatBLP(constant,64),buildBLP(constant,64,64));
const hiddenA=Buffer.from(constant),hiddenB=Buffer.from(constant);
for(let y=0;y<64;y++)for(let x=0;x<20;x++) {
  const p=(y*64+x)*4;
  hiddenA.set([0,0,0,0],p);hiddenB.set([255,0,255,0],p);
}
assert.deepEqual(buildBoatBLP(hiddenA,64),buildBoatBLP(hiddenB,64),'Invisible RGB must not leak into filtered colour');
console.log(`Skycutter downsampling PASS: ${changes} channel adjustments; source/alpha/soft edges preserved, ringing bounded, constant colour and transparency checks passed`);
