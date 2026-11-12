const assert=require('node:assert/strict'),fs=require('node:fs');
const {buildSize,widths}=require('./Build-SkycutterSizes.cjs');
const base=fs.readFileSync('Media/SkycutterBoatStaticProbe.tga').subarray(18);
function coverage(pixels,stride,w,h) {
  let a=0,xsum=0,ysum=0;
  for(let y=0;y<h;y++)for(let x=0;x<w;x++) {
    const value=pixels[(y*stride+x)*4+3];a+=value;xsum+=(x+.5)*value;ysum+=(y+.5)*value;
  }
  return {mean:a/(w*h),x:xsum/a/w,y:ysum/a/h};
}
const original=coverage(base,1024,1024,1024);
for(const w of widths) {
  const h=w*2/3,file=`Media/SkycutterBoatSize${w}.tga`,tga=fs.readFileSync(file);
  assert.deepEqual(tga,buildSize(base,1024,1024,w,h),'Each size derives directly from untouched baseline');
  const tw=tga.readUInt16LE(12),th=tga.readUInt16LE(14),pixels=tga.subarray(18);
  assert.equal(tga[2],2);assert.equal(tga[16],32);assert.equal(tga[17],40);
  assert.equal(tw,2**Math.ceil(Math.log2(w)));assert.equal(th,2**Math.ceil(Math.log2(h)));
  assert.equal(tga.length,18+tw*th*4);
  assert.ok(!fs.existsSync(file.replace('.tga','.blp')),'No same-stem mipmapped asset');
  for(let y=0;y<th;y++)for(let x=0;x<tw;x++)if(x>=w||y>=h)assert.equal(pixels[(y*tw+x)*4+3],0,'Padding stays transparent');
  const result=coverage(pixels,tw,w,h);
  assert.ok(Math.abs(result.mean-original.mean)<.5,'Preserve integrated alpha coverage');
  assert.ok(Math.abs(result.x-original.x)*w<1 && Math.abs(result.y-original.y)*h<1,'Preserve artwork registration');
}
const constant=Buffer.alloc(32*32*4);
for(let p=0;p<constant.length;p+=4)constant.set([35,125,210,255],p);
const t=buildSize(constant,32,32,24,16);
for(let y=0;y<16;y++)for(let x=0;x<24;x++)assert.deepEqual([...t.subarray(18+(y*32+x)*4,22+(y*32+x)*4)],[35,125,210,255]);
const a=Buffer.from(constant),b=Buffer.from(constant);
for(let y=0;y<32;y++)for(let x=0;x<12;x++){const p=(y*32+x)*4;a.set([0,0,0,0],p);b.set([255,0,255,0],p);}
assert.deepEqual(buildSize(a,32,32,24,16),buildSize(b,32,32,24,16),'Invisible RGB cannot contaminate filtered edges');
assert.throws(()=>buildSize(constant,32,32,64,16),/dimensions/);
console.log('Skycutter sizes PASS: seven reproducible direct-baseline TGAs, 3:2 content, power-of-two padding, coverage/registration, constant colour and hidden-RGB isolation');
