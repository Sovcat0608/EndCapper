const assert=require('node:assert/strict'),fs=require('node:fs');
const {files,read,outputName,convert}=require('./Build-ArtworkCAS.cjs');
assert.equal(new Set(files).size,files.length);
// Every base and separate ice overlay in the artwork registry has a CAS pair.
const registry=fs.readFileSync('Model.lua','utf8').split('\n').filter(line=>!line.includes('floatingOnly=true')).join('\n');
const paths=[...registry.matchAll(/(?:path|overlay)\s*=\s*"Interface\\\\AddOns\\\\EndCapper\\\\Media\\\\([^"\r\n]+)"/g)].map(m=>'Media/'+m[1]);
assert.equal(paths.length,32,'30 static bases plus two ice overlays; two floating-only books checked separately');
const baselines=require('./baseline-artwork.json');
assert.deepEqual([...baselines].sort(),[...paths].sort(),'Package baseline manifest matches static registry');
const pkgmeta=fs.readFileSync('.pkgmeta','utf8').split(/\r?\n/);
for(const file of paths) {
  assert(files.includes(file),'Missing archived artwork CAS pair: '+file);
  assert(!pkgmeta.includes('  - '+file),'Original baseline must ship: '+file);
  assert(pkgmeta.includes('  - '+file.replace(/\.(tga|blp)$/,'CAS.$1')),'Static CAS must stay build-only: '+file);
}
for(const file of files) {
  const original=read(file),result=fs.readFileSync(outputName(file));
  assert.deepEqual(result,convert(original,file),'Reproducible CAS: '+file);
  const ranges=[];
  if(file.endsWith('.tga')) {
    assert.deepEqual(result.subarray(0,18),original.subarray(0,18));
    ranges.push([18,original.length]);
  } else {
    assert.deepEqual(result.subarray(0,148),original.subarray(0,148),'Mip layout untouched');
    for(let i=0;i<16;i++) {
      const start=original.readUInt32LE(20+i*4),length=original.readUInt32LE(84+i*4);
      if(length)ranges.push([start,start+length]);
    }
  }
  for(const [start,end] of ranges)for(let p=start;p<end;p+=4) {
    assert.equal(result[p+3],original[p+3],'Alpha and clipping silhouette exact: '+file);
    if(original[p+3]<=224)for(let c=0;c<3;c++)assert.equal(result[p+c],original[p+c],'Soft glow/edge protected: '+file);
  }
}
console.log(`Artwork CAS PASS: ${files.length} source pairs, all bases/overlays, exact alpha, original mip layouts, protected bloom and reproducible maximum CAS`);
