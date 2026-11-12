const assert=require('node:assert/strict'),fs=require('node:fs');
const {names,sizes,source}=require('./Build-ArcaneCAS.cjs');
const {buildSize}=require('./Build-SkycutterSizes.cjs');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
for(const name of names) {
  const original=source(name);let changed=0;
  for(const size of sizes) {
    const base=buildSize(original,256,256,size,size);
    assert.deepEqual(fs.readFileSync(`Media/${name}Size${size}.tga`),base,'Toggle-off keeps identical resampling and UV padding');
    const result=fs.readFileSync(`Media/${name}CASSize${size}.tga`);
    assert.deepEqual(result,sharpen(base,size,size),'Reproducible original-level-zero size and CAS');
    assert.deepEqual(result.subarray(0,18),base.subarray(0,18));
    for(let p=18;p<result.length;p+=4) {
      assert.equal(result[p+3],base[p+3],'Registered alpha exact after CAS');
      if(base[p+3]<=224)assert.deepEqual(result.subarray(p,p+4),base.subarray(p,p+4),'Protected edge unchanged');
      if(!result.subarray(p,p+3).equals(base.subarray(p,p+3)))changed++;
    }
  }
  console.log(`Arcane CAS PASS: ${name}, five reproducible textures, exact coverage/registration, ${changed} RGB pixels sharpened`);
}
