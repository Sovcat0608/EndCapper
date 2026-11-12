const assert=require('node:assert/strict');
const fs=require('node:fs');
const {softenAlpha}=require('./Build-SkycutterEdgeAA.cjs');
const base=fs.readFileSync('Media/SkycutterBoatStaticProbe.tga');
const trial=fs.readFileSync('Media/SkycutterBoatEdgeAA.tga');
assert.equal(trial.length,base.length);
assert.deepEqual(trial.subarray(0,18),base.subarray(0,18));
assert.deepEqual(trial.subarray(18),softenAlpha(base.subarray(18),1024,1024));
assert.ok(!fs.existsSync('Media/SkycutterBoatEdgeAA.blp'),'No same-stem BLP may override the TGA trial');
let changed=0,interior=0,coverageBefore=0,coverageAfter=0;
for(let y=0;y<1024;y++)for(let x=0;x<1024;x++) {
  const p=18+(y*1024+x)*4;
  for(let c=0;c<3;c++)assert.equal(trial[p+c],base[p+c],'No colour or detail filtering');
  if(base[p+3]===0 && base[p]===0 && base[p+1]===0 && base[p+2]===0)
    assert.equal(trial[p+3],0,'Do not reveal black outside existing colour bleed');
  let lo=255,hi=0;
  for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++) {
    const q=18+(Math.max(0,Math.min(1023,y+dy))*1024+Math.max(0,Math.min(1023,x+dx)))*4;
    lo=Math.min(lo,base[q+3]);hi=Math.max(hi,base[q+3]);
  }
  assert.ok(trial[p+3]>=lo && trial[p+3]<=hi,'Positive kernel cannot introduce ringing');
  if(lo===hi)assert.equal(trial[p+3],base[p+3],'Uniform interiors and distant transparency remain exact');
  if(lo>=240){interior++;assert.equal(trial[p+3],base[p+3],'Near-opaque painted interiors stay exact');}
  if(trial[p+3]!==base[p+3])changed++;
  coverageBefore+=base[p+3];coverageAfter+=trial[p+3];
}
assert.ok(changed>1000 && interior>10000);
assert.ok(Math.abs(coverageAfter-coverageBefore)/coverageBefore<0.001,'Preserve total opacity within rounding tolerance');
// A coloured alpha impulse with a pre-existing transparent colour bleed.
const impulse=Buffer.alloc(5*5*4);
for(let i=0;i<impulse.length;i+=4)impulse.set([35,125,210,0],i);
impulse[4*(2*5+2)+3]=255;
const soft=softenAlpha(impulse,5,5);
assert.equal(soft[4*(2*5+2)+3],64);
assert.equal(soft[4*(2*5+1)+3],32);
assert.equal(soft[4*(1*5+1)+3],16);
assert.equal(soft[3],0);
const opaque=Buffer.alloc(4*4*4,255);assert.deepEqual(softenAlpha(opaque,4,4),opaque);
assert.throws(()=>softenAlpha(Buffer.alloc(3),1,1),/BGRA/);
console.log(`Skycutter edge AA PASS: ${changed} localized alpha changes, ${interior} unchanged near-opaque interior texels, every RGB byte preserved, bounded kernel and coverage`);
