// Maximum accepted CAS, baked alongside originals. No runtime shader or resize.
const fs=require('node:fs'),path=require('node:path');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
const root=path.join(__dirname,'..');
const files=require('./artwork-cas.json');
const external=require('./external-media.json');
function read(file) {return fs.readFileSync(fs.existsSync(path.join(root,file))?path.join(root,file):external[file]);}
function outputName(file) {return file.replace(/\.(tga|blp)$/, 'CAS.$1');}
function convert(b,file) {
  if(file.endsWith('.tga'))return sharpen(b,b.readUInt16LE(12),b.readUInt16LE(14));
  // Retain the original halo mip chain, dimensions, alpha and filtering.
  if(b.toString('ascii',0,4)!=='BLP2'||b[8]!==3||b[9]!==8||b[10]!==2)throw Error('Expected lossless BGRA BLP: '+file);
  const out=Buffer.from(b);
  for(let i=0;i<16;i++) {
    const offset=b.readUInt32LE(20+i*4),length=b.readUInt32LE(84+i*4);
    if(!offset&&!length)continue;
    const w=Math.max(1,b.readUInt32LE(12)>>i),h=Math.max(1,b.readUInt32LE(16)>>i);
    if(length!==w*h*4||offset+length>b.length)throw Error('Invalid BLP mip: '+file);
    const t=Buffer.alloc(18+length);t[2]=2;t[16]=32;t[17]=40;t.writeUInt16LE(w,12);t.writeUInt16LE(h,14);
    b.copy(t,18,offset,offset+length);
    sharpen(t,w,h).copy(out,offset,18);
  }
  return out;
}
if(require.main===module)for(const file of files) {
  fs.writeFileSync(path.join(root,outputName(file)),convert(read(file),file));
  console.log('CAS:',file);
}
module.exports={files,read,outputName,convert};
