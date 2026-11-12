// Same size-specific, alpha-correct resampling and CAS recipe as Skycutter.
const fs=require('node:fs'),path=require('node:path');
const {buildSize}=require('./Build-SkycutterSizes.cjs');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
const names=['ArcaneCrystal','ArcaneSigil','SoulboundCrystal','SoulboundCrystalEmission'];
const sizes=[64,96,128,192,256];
function source(name) {
  const b=fs.readFileSync(path.join(__dirname,'../Media',name+'.blp'));
  if(b.toString('ascii',0,4)!=='BLP2'||b[8]!==3||b[9]!==8||b[10]!==2||b.readUInt32LE(12)!==256||b.readUInt32LE(16)!==256)
    throw Error('Expected lossless original 256-square BGRA BLP');
  const start=b.readUInt32LE(20),length=b.readUInt32LE(84);
  if(length!==256*256*4||start+length>b.length)throw Error('Invalid original level zero');
  return b.subarray(start,start+length);
}
if(require.main===module)for(const name of names) {
  const original=source(name);
  for(const size of sizes) {
    const baseline=buildSize(original,256,256,size,size);
    fs.writeFileSync(path.join(__dirname,'../Media',`${name}Size${size}.tga`),baseline);
    const tga=sharpen(baseline,size,size);
    fs.writeFileSync(path.join(__dirname,'../Media',`${name}CASSize${size}.tga`),tga);
  }
  console.log(`${name}: five CAS sizes, original alpha registration retained`);
}
module.exports={names,sizes,source};
