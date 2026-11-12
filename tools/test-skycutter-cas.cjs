const assert=require('node:assert/strict'),fs=require('node:fs');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
const {widths}=require('./Build-SkycutterSizes.cjs');
for(const w of widths) {
  const file=`Media/SkycutterBoatSize${w}.tga`,base=fs.readFileSync(file),out=fs.readFileSync(`Media/SkycutterBoatCASSize${w}.tga`);
  const before=Buffer.from(base);
  assert.deepEqual(out,sharpen(base,w,w*2/3),'Reproducible CAS');
  assert.deepEqual(base,before,'Sharpening does not mutate Babe input');
  assert.deepEqual(out.subarray(0,18),base.subarray(0,18));
  let changed=0;
  for(let p=18;p<base.length;p+=4) {
    assert.equal(out[p+3],base[p+3],'Exact alpha');
    if(base[p+3]<=224)assert.deepEqual(out.subarray(p,p+4),base.subarray(p,p+4),'Protected transparent edge');
    if(!out.subarray(p,p+3).equals(base.subarray(p,p+3)))changed++;
  }
  assert.ok(changed>100,'Actual colour sharpening');
  console.log(`CAS ${w}: ${changed} RGB pixels changed; alpha and Babe exact`);
}
const tga=Buffer.alloc(18+5*5*4);tga[2]=2;tga[16]=32;tga[17]=40;tga.writeUInt16LE(5,12);tga.writeUInt16LE(5,14);
for(const value of [0,100,255]) {
  for(let p=18;p<tga.length;p+=4)tga.set([value,value,value,255],p);
  assert.deepEqual(sharpen(tga,5,5),tga,'Flat colour/black/white stable');
}
for(let p=18;p<tga.length;p+=4)tga.set([100,100,100,255],p);
const centre=18+(2*5+2)*4;tga.set([130,130,130,255],centre);
const out=sharpen(tga,5,5);
assert.ok(out[centre]>130,'Soft bright detail gains contrast');
assert.deepEqual(sharpen(tga,5,5,0),tga,'Zero blend bypass');
// Independent scalar CAS reference for this grey cross in linear light.
const lin=x=>((x/255+0.055)/1.055)**2.4;
const lo=lin(100),hi=lin(130),weight=-Math.sqrt(Math.min(lo,1-hi)/hi)/5;
const filtered=(hi+weight*4*lo)/(1+4*weight),mixed=hi+.65*(filtered-hi);
assert.equal(out[centre],Math.round(255*(1.055*mixed**(1/2.4)-.055)));
tga[18+(1*5+1)*4+3]=0;
assert.deepEqual(sharpen(tga,5,5).subarray(centre,centre+4),tga.subarray(centre,centre+4),'Diagonal transparent neighbour protects centre');
assert.throws(()=>sharpen(tga,6,5),/Invalid/);
console.log('CAS PASS: reference kernel, linear conversion, alpha protection, immutable Babe, stable flat fields and reproducibility');
