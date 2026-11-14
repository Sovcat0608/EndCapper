const fs=require('node:fs'),assert=require('node:assert/strict'),crypto=require('node:crypto');
const names=['ColdsnapDetails','ColdsnapPupilAtlas','ColdsnapFlowAtlas','CombustionSeal','CombustionFlameAtlas'];
for(const name of names){
 const atlas=name.endsWith('Atlas'),w=atlas?2048:512,h=atlas?1024:512;
 const b=fs.readFileSync('Media/'+name+'.tga');
 assert.equal(b.length,18+w*h*4);assert.equal(b[2],2);assert.equal(b[16],32);assert.equal(b[17],40);
 assert.equal(b.readUInt16LE(12),w);assert.equal(b.readUInt16LE(14),h);
 const color=name.startsWith('Cold')?[255,194,36]:[35,190,255];
 let visible=0;
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const p=18+(y*w+x)*4;
  if(atlas&&(x%256<4||x%256>=252||y%256<4||y%256>=252))assert.equal(b[p+3],0,'Empty gutters prevent neighboring frame bleed');
  if(b[p+3]>64){
   visible++;if(name.startsWith('Cold'))for(let k=0;k<3;k++)assert(Math.abs(b[p+k]-color[k])<=1,'Coldsnap keeps flat emissive RGB');
  }
 }
 assert(visible>100);
 if(atlas){
  const hashes=new Set(),centers=[],framePixels=[];
  for(let frame=0;frame<32;frame++){
   const pixels=Buffer.alloc(256*256*4);let weight=0,cx=0,cy=0;
   for(let y=0;y<256;y++){
    const start=18+((Math.floor(frame/8)*256+y)*w+(frame%8)*256)*4;
    b.copy(pixels,y*256*4,start,start+256*4);
    for(let x=0;x<256;x++){const a=b[start+x*4+3];weight+=a;cx+=a*x;cy+=a*y;}
   }
   hashes.add(crypto.createHash('sha256').update(pixels).digest('hex'));centers.push([cx/weight,cy/weight]);framePixels.push(pixels);
   if(name==='CombustionFlameAtlas')for(let y=132;y<160;y++)for(let x=120;x<132;x++)
    assert.equal(pixels[(y*256+x)*4+3],0,'Flame interior must remain genuinely transparent in every frame');
  }
  assert.equal(hashes.size,32,'Every frame changes spatially');
  if(name==='ColdsnapPupilAtlas'){
   assert(Math.max(...centers.map(c=>c[0]))-Math.min(...centers.map(c=>c[0]))>10,'Pupil looks sideways');
   assert(Math.max(...centers.map(c=>c[1]))-Math.min(...centers.map(c=>c[1]))>5,'Pupil looks up/down');
  }
  if(name==='CombustionFlameAtlas'){
   for(let axis=0;axis<2;axis++)assert(Math.max(...centers.map(c=>c[axis]))-Math.min(...centers.map(c=>c[axis]))<2,'Subtle motion, no whole-flame wandering');
   for(let f=0;f<32;f++){
    let difference=0,coverage=0;const a=framePixels[f],b=framePixels[(f+1)%32];
    for(let p=3;p<a.length;p+=4){difference+=Math.abs(a[p]-b[p]);coverage+=a[p];}
    assert(difference/coverage<.06,'Small coherent frame changes, including the loop seam');
   }
  }
 }else if(name==='CombustionSeal'){
  for(let y=192;y<320;y++)for(let x=192;x<320;x++)assert.equal(b[21+(y*w+x)*4],0,'Hollow transparent center');
  let gaps=0,ring=0;const colors=new Set();
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
   const p=18+(y*w+x)*4,r=Math.hypot(x-256,y-256);
   if(r>165&&r<200){ring++;if(b[p+3]===0)gaps++;}
   if(b[p+3]>128)colors.add(b.subarray(p,p+3).toString('hex'));
  }
  assert(gaps>ring*.2,'See-through spaces between the original glyphs');
  assert(colors.size>100,'Preserve the painted gold highlights instead of flattening RGB');
 }
}
console.log('Mage sigil assets PASS: 5 RGBA textures, 32 unique frames/layer, moving pupil, transparent gaps/gutters and restored painted Combustion');
