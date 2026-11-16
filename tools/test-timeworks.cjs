const fs=require('node:fs'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
function read(name,w,h){
 const b=fs.readFileSync(`Media/${name}.tga`);
 assert.equal(b.length,18+w*h*4);assert.equal(b.readUInt16LE(12),w);assert.equal(b.readUInt16LE(14),h);
 assert.equal(b[2],2);assert.equal(b[16],32);assert.equal(b[17],40);
 let clear=0,solid=0;for(let p=21;p<b.length;p+=4){if(b[p]===0)clear++;else solid++;}
 assert(clear>100&&solid>100,`${name} has meaningful alpha`);return b;
}
for(const name of ['Timekeeper','Timelost','TimelostFront'])read(name,512,512);
const front=read('TimelostFront',512,512);
for(const name of ['Timekeeper','Timelost']) {
 const core=read(name+'GlyphEmissionCAS',512,512),halo=read(name+'GlyphBloomCAS',256,256);
 const a=(x,y)=>core[21+(Math.floor(y/724*512)*512+Math.floor(x/1086*512))*4];
 for(const [x,y] of name==='Timekeeper'?[[390,455],[390,565],[505,210],[390,280]]:[[866,298],[818,413],[914,440],[715,290]])assert.equal(a(x,y),0,'Sand, eyes, gems and gears excluded from glyph mask');
 let glow=0;for(let p=21;p<core.length;p+=4)if(core[p]>20)glow++;
 assert(glow>150&&glow<5000,'Glyph-only coverage');
 let haloPixels=0;for(let p=21;p<halo.length;p+=4)if(halo[p]>3)haloPixels++;
 assert(haloPixels>glow/4,'Soft local bloom extends the core');
}
const alpha=(x,y)=>front[21+(Math.floor(y/724*512)*512+Math.floor(x/1086*512))*4];
assert.equal(alpha(870,300),0,'Top gear recess open');
assert(alpha(900,355)>200,'Crossbar occludes gears');
assert(alpha(870,491)>200,'Ribbon remains foreground');
for(let g=1;g<=3;g++)for(const n of [64,96,128,192,256]){
 const backing=2**Math.ceil(Math.log2(n)),b=read(`TimelostGear${g}CASSize${n}`,backing,backing);
 for(let y=0;y<backing;y++)for(let x=0;x<backing;x++)if(x>=n||y>=n)assert.equal(b[21+(y*backing+x)*4],0,'Backing outside UV stays clear');
}
const atlas=read('TimekeeperSandAtlasCAS',1024,512),hashes=new Set();
for(let f=0;f<32;f++){
 const cell=Buffer.alloc(128*128*4);
 for(let y=0;y<128;y++)for(let x=0;x<128;x++){
  const p=18+((Math.floor(f/8)*128+y)*1024+(f%8)*128+x)*4;
  atlas.copy(cell,(y*128+x)*4,p,p+4);
  if(x<3||y<3||x>=125||y>=125)assert.equal(atlas[p+3],0,'Atlas sampling gutter clear');
  // Clear glass between falling stream and reservoir must never shimmer.
  if(x>75&&x<85&&y>62&&y<69)assert.equal(atlas[p+3],0,'Glass excluded from sand mask');
 }
 hashes.add(crypto.createHash('sha256').update(cell).digest('hex'));
}
assert.equal(hashes.size,32,'Every sand frame unique');
console.log('Timeworks assets PASS: layered occlusion, 15 padded gear variants, 32 distinct sand frames, clear gutters and protected glass');
