const assert=require('node:assert/strict');
const fs=require('node:fs');
const {buildBLP}=require('./Build-HaloMipmaps.cjs');
const {buildRefinedBLP}=require('./Build-SkycutterRefinedMipmaps.cjs');
const base=fs.readFileSync('Media/SkycutterBoatStaticProbe.tga').subarray(18);
const trial=fs.readFileSync('Media/SkycutterBoatRefined.blp');
const box=buildBLP(base,1024,1024),prior=fs.readFileSync('Media/SkycutterBoat.blp');
assert.deepEqual(trial,buildRefinedBLP(base),'Trial must reproduce from the sharp baseline');
assert.deepEqual(trial.subarray(0,1172),box.subarray(0,1172));
assert.deepEqual(trial.subarray(1172,1172+base.length),base,'Full-resolution source must remain exact');
let edgeChanges=0,colourChanges=0;
for(let level=1;level<=10;level++) {
  const size=1024>>level,offset=trial.readUInt32LE(20+level*4),length=trial.readUInt32LE(84+level*4);
  if(size<16) {
    assert.deepEqual(trial.subarray(offset,offset+length),box.subarray(offset,offset+length));
    continue;
  }
  for(let y=0;y<size;y++)for(let x=0;x<size;x++) {
    const p=offset+(y*size+x)*4;
    let low=255,high=0;
    for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++) {
      const q=offset+(Math.max(0,Math.min(size-1,y+dy))*size+Math.max(0,Math.min(size-1,x+dx)))*4;
      low=Math.min(low,box[q+3]);high=Math.max(high,box[q+3]);
    }
    assert.ok(trial[p+3]>=low && trial[p+3]<=high,'Alpha ringing must stay inside local coverage bounds');
    if(trial[p+3]!==prior[p+3])edgeChanges++;
    if(trial[p+3]>0)for(let c=0;c<3;c++)if(trial[p+c]!==prior[p+c])colourChanges++;
  }
}
assert.ok(edgeChanges>1000 && colourChanges>1000,'Trial must differ meaningfully from the rejected chain');
const constant=Buffer.alloc(64*64*4);
for(let i=0;i<constant.length;i+=4)constant.set([35,125,210,255],i);
assert.deepEqual(buildRefinedBLP(constant,64),buildBLP(constant,64,64),'Constant colours must be preserved');
const a=Buffer.from(constant),b=Buffer.from(constant);
for(let y=0;y<64;y++)for(let x=0;x<20;x++) {
  a.set([0,0,0,0],(y*64+x)*4);b.set([255,0,255,0],(y*64+x)*4);
}
const aa=buildRefinedBLP(a,64),bb=buildRefinedBLP(b,64),mipStart=aa.readUInt32LE(24);
assert.deepEqual(aa.subarray(mipStart),bb.subarray(mipStart),'Invisible RGB must not tint reduced levels');
console.log(`Refined Skycutter PASS: exact source, reproducible mips, ${edgeChanges} alpha / ${colourChanges} colour differences, bounded coverage, constant colour and hidden-RGB isolation`);
