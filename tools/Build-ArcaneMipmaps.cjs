// Reuse the halo encoder approved in-game; retain the original source TGAs.
const fs=require('node:fs');
const path=require('node:path');
const {buildBLP}=require('./Build-HaloMipmaps.cjs');
const output=process.argv[2];
if(!output)throw Error('Usage: node Build-ArcaneMipmaps.cjs <output Media directory>');
fs.mkdirSync(output,{recursive:true});
for(const name of ['ArcaneCrystal','ArcaneSigil']) {
  const tga=fs.readFileSync(path.join(__dirname,'../Media',name+'.tga'));
  if(tga[0]!==0||tga[1]!==0||tga[2]!==2||tga[16]!==32||tga[17]!==40)throw Error('Expected top-left 32-bit alpha TGA');
  const w=tga.readUInt16LE(12),h=tga.readUInt16LE(14);
  const blp=buildBLP(tga.subarray(18),w,h);
  fs.writeFileSync(path.join(output,name+'.blp'),blp);
  console.log(`${name}: ${w}x${h} BLP2/BGRA, full mip chain, ${blp.length} bytes`);
}
