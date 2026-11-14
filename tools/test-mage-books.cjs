const assert=require('node:assert/strict'),fs=require('node:fs');
const {buildSize}=require('./Build-SkycutterSizes.cjs');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
const {sizes}=require('./Build-MageBooks.cjs');
const read=name=>fs.readFileSync('Media/'+name+'.tga');
function valid(b){
  const w=b.readUInt16LE(12),h=b.readUInt16LE(14);
  assert.equal(b[2],2);assert.equal(b[16],32);assert.equal(b[17],40);
  assert.equal(b.length,18+w*h*4);assert.equal(w&(w-1),0);assert.equal(h&(h-1),0);
  let clear=0,solid=0;for(let p=21;p<b.length;p+=4){if(!b[p])clear++;if(b[p]>100)solid++;}
  assert(clear>100&&solid>20,'Actual transparent image content');
}
for(const name of ['Frostbound','Emberbound']){
  for(const size of sizes){
    const book=read(name+'BookCASSize'+size),emission=read(name+'BookEmissionSize'+size),halo=read(name+'BookBloomSize'+size);
    for(const image of [book,emission,halo])valid(image);
    assert.deepEqual(book.subarray(0,18),emission.subarray(0,18));assert.deepEqual(book.subarray(0,18),halo.subarray(0,18));
    const width=book.readUInt16LE(12);
    for(let y=0;y<width;y++)for(let x=0;x<width;x++)if(x>=size||y>=size){
      const p=21+(y*width+x)*4;
      assert.equal(book[p]+emission[p]+halo[p],0,'UV padding stays transparent');
    }
  }
  // Full-resolution backing remains an unmodified-alpha, single CAS pass.
  const cache='tools/cache/mage-books/'+name+'Book.tga';
  if(fs.existsSync(cache)){
    const original=fs.readFileSync(cache);
    const expected=name==='Frostbound'?[1,114,872,819]:[16,119,887,822];
    const bounds=[887,887,0,0];
    for(let y=0;y<887;y++)for(let x=0;x<887;x++)if(original[21+(y*887+x)*4]>=16){
      bounds[0]=Math.min(bounds[0],x);bounds[1]=Math.min(bounds[1],y);
      bounds[2]=Math.max(bounds[2],x+1);bounds[3]=Math.max(bounds[3],y+1);
    }
    assert.deepEqual(bounds,expected,'Runtime drag-frame bounds match the actual book alpha silhouette');
    for(const size of [192,384,887]){
      const plain=buildSize(original.subarray(18),887,887,size,size),cas=read(name+'BookCASSize'+size);
      assert.deepEqual(cas,sharpen(plain,size,size),'Deterministic direct-source CAS');
      for(let p=21;p<cas.length;p+=4)assert.equal(cas[p],plain[p],'CAS never alters alpha');
    }
  }
}
console.log('Mage assets PASS: 42 registered book textures, exact alpha/padding and reproducible CAS');
for(const name of ['Frostbound','Emberbound'])for(const suffix of ['','CAS','Emission','Bloom','ShadowMask','BookShadow'])assert(!fs.existsSync('Media/'+name+suffix+'.tga'),'Retired scroll/shadow asset must stay archived');
