// Approved v6 sheets only: split pixels, registered emission masks and the
// accepted premultiplied Lanczos2 / alpha-protected maximum-CAS size variants.
const fs=require('node:fs'),path=require('node:path');
const {buildSize}=require('./Build-SkycutterSizes.cjs');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
const cache=path.join(__dirname,'cache/mage-books'),media=path.join(__dirname,'../Media');
const sizes=[192,288,384,480,576,768,887];
const clamp=x=>Math.max(0,Math.min(1,x));
function tga(pixels,w,h){
  const header=Buffer.alloc(18);header[2]=2;header[16]=32;header[17]=40;
  header.writeUInt16LE(w,12);header.writeUInt16LE(h,14);
  return Buffer.concat([header,pixels]);
}
function blur(input,w,h,r){
  let a=Float32Array.from(input);
  for(let pass=0;pass<3;pass++){
    const b=new Float32Array(w*h),c=new Float32Array(w*h);
    for(let y=0;y<h;y++)for(let x=0;x<w;x++){
      let sum=0;for(let dx=-r;dx<=r;dx++)sum+=a[y*w+Math.max(0,Math.min(w-1,x+dx))];
      b[y*w+x]=sum/(2*r+1);
    }
    for(let y=0;y<h;y++)for(let x=0;x<w;x++){
      let sum=0;for(let dy=-r;dy<=r;dy++)sum+=b[Math.max(0,Math.min(h-1,y+dy))*w+x];
      c[y*w+x]=sum/(2*r+1);
    }
    a=c;
  }
  return a;
}
function masks(pixels,w,h,frost){
  const core=Buffer.alloc(pixels.length),alpha=new Float32Array(w*h);
  for(let i=0;i<w*h;i++){
    const p=i*4,b=pixels[p],g=pixels[p+1],r=pixels[p+2],a=pixels[p+3];
    // Select chromatic glyphs/gems and element edges, leaving neutral parchment
    // and dark leather quiet. The fire threshold excludes cream and bronze.
    const strength=frost ? clamp((b-r-14)/65)*clamp((b-60)/100)
      : clamp((r-g-36)/80)*clamp((r-b-70)/100)*clamp((r-90)/100);
    const weight=strength*a;
    alpha[i]=weight;core[p+3]=Math.round(weight);
    const color=frost?[255,200,100]:[25,125,255];
    for(let c=0;c<3;c++)core[p+c]=color[c];
  }
  const halo=blur(alpha,w,h,Math.max(1,Math.round(w/220))),bloom=Buffer.alloc(pixels.length);
  for(let i=0;i<w*h;i++){
    // Small soft halo, never an opaque square or a second copy of the artwork.
    bloom[i*4]=frost?255:20;bloom[i*4+1]=frost?160:100;bloom[i*4+2]=frost?60:255;
    bloom[i*4+3]=Math.min(180,Math.round(halo[i]*1.5));
  }
  return {core,bloom};
}
function build(){
  const manifest={sources:JSON.parse(fs.readFileSync(path.join(cache,'sources.json'),'utf8').replace(/^\uFEFF/,'')),files:[],baselines:{},sizes};
  function save(name,data){fs.writeFileSync(path.join(media,name+'.tga'),data);manifest.files.push('Media/'+name+'.tga');}
  for(const source of manifest.sources){
    let w=source.width,h=source.height,pixels=fs.readFileSync(path.join(cache,source.name+'.bgra'));
    const book=source.name.endsWith('Book'),name=source.name.replace(/Base$/,'');
    if(!book)continue;
    const {core,bloom}=masks(pixels,w,h,name.startsWith('Frost'));
    // Full-resolution source/mask snapshots support registration checks/previews.
    for(const [suffix,data] of [['',pixels],['Emission',core],['Bloom',bloom]])fs.writeFileSync(path.join(cache,name+suffix+'.tga'),tga(data,w,h));
    if(book){
      for(const size of sizes){
        const plain=buildSize(pixels,w,h,size,size);
        save(name+'CASSize'+size,sharpen(plain,size,size));
        for(const [suffix,data] of [['Emission',core],['Bloom',bloom]])save(name+suffix+'Size'+size,buildSize(data,w,h,size,size));
      }
    }
  }
  fs.writeFileSync(path.join(cache,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  console.log(JSON.stringify({files:manifest.files.length,baselines:manifest.baselines}));
}
if(require.main===module)build();
module.exports={masks,sizes};
