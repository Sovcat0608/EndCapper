const assert=require('node:assert/strict'),fs=require('node:fs');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
const base=fs.readFileSync('Media/Zephyr.tga'),cas=fs.readFileSync('Media/ZephyrCAS.tga');
assert.deepEqual(cas,sharpen(base,1024,1024),'Reproducible single CAS pass from original');
assert.deepEqual(cas.subarray(0,18),base.subarray(0,18));
let changed=0;
for(let p=18;p<base.length;p+=4) {
  assert.equal(cas[p+3],base[p+3],'Alpha and crop baseline preserved');
  if(base[p+3]<=224)assert.deepEqual(cas.subarray(p,p+4),base.subarray(p,p+4),'Soft edges preserved');
  if(!cas.subarray(p,p+3).equals(base.subarray(p,p+3)))changed++;
}
assert.ok(changed>1000,'Meaningful interior colour sharpening');
console.log(`Zephyr CAS PASS: ${changed} RGB pixels changed, exact dimensions/header/alpha and protected edges`);
