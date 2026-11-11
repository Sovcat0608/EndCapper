// Derive animation only from approved runtime stream pixels. Never rewrite bases.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const regions={Cryptgate:{x:174,y:400,w:44,h:68,hash:'A0B5566496A5CCDEA992C2EB810236A4721D833778D9FDF1ED0484C214A22E4E'},Plaguewell:{x:385,y:322,w:38,h:94,hash:'AFFF4AD48E9011A17336B978B6FDD48A99A7ABD5969787E4B6D6DF96DD2C85F2'}};
const frames=64,cell=128,pad=2,size=1024,fps=24;
const clamp=v=>Math.max(0,Math.min(1,v));
const smooth=(a,b,v)=>{const t=clamp((v-a)/(b-a));return t*t*(3-2*t);};
const hash=b=>crypto.createHash('sha256').update(b).digest('hex').toUpperCase();
function sample(src,x,y) {
  x=Math.max(0,Math.min(511,x));y=Math.max(0,Math.min(511,y));
  const ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy,out=[0,0,0,0];
  for(let dy=0;dy<2;dy++)for(let dx=0;dx<2;dx++){
    const p=18+(Math.min(511,iy+dy)*512+Math.min(511,ix+dx))*4;
    const weight=(dx?fx:1-fx)*(dy?fy:1-fy);
    for(let c=0;c<4;c++)out[c]+=src[p+c]*weight;
  }
  return out;
}
function mask(pixel,u,v) {
  const [b,g,r,a]=pixel;
  // Green liquid only: exclude warm bone, grey stone, and the channel beyond the fall.
  return a/255*smooth(18,50,g-r)*smooth(40,105,g-b)*smooth(75,140,g)*
    smooth(0,0.07,v)*(1-smooth(0.91,1,v))*smooth(0,0.05,u)*(1-smooth(0.95,1,u));
}
function colour(pixel,u,v,phase) {
  // Integer temporal frequencies loop exactly. Crests move DOWN the stationary
  // silhouette; differing lateral phase makes rivulets, not a whole-stream pulse.
  const wave=Math.sin(2*Math.PI*(v*3-phase*2+0.14*Math.sin(u*9)));
  const fine=Math.sin(2*Math.PI*(v*7-phase*5+u*0.6));
  const factor=0.88+0.23*wave+0.09*fine;
  const crest=Math.pow(Math.max(0,wave),6)*0.12;
  return pixel.slice(0,3).map((c,i)=>Math.round(Math.min(255,c*factor+crest*[34,60,80][i])));
}
function build(src,region) {
  if(hash(src)!==region.hash)throw Error('Base changed: review stream registration before rebuilding');
  const out=Buffer.alloc(18+size*size*4);out[2]=2;out[16]=32;out[17]=40;
  out.writeUInt16LE(size,12);out.writeUInt16LE(size,14);
  for(let f=0;f<frames;f++)for(let y=0;y<cell;y++)for(let x=0;x<cell;x++){
    // Duplicate edge texels into the two-pixel gutter to prevent cell bleed.
    const u=(Math.max(pad,Math.min(cell-pad-1,x))-pad+0.5)/(cell-2*pad);
    const v=(Math.max(pad,Math.min(cell-pad-1,y))-pad+0.5)/(cell-2*pad);
    const pixel=sample(src,region.x+u*region.w-0.5,region.y+v*region.h-0.5);
    const alpha=Math.round(255*0.92*mask(pixel,u,v));
    const p=18+((Math.floor(f/8)*cell+y)*size+(f%8)*cell+x)*4;
    const rgb=colour(pixel,u,v,f/frames);
    for(let c=0;c<3;c++)out[p+c]=rgb[c];out[p+3]=alpha;
  }
  return out;
}
if(require.main===module){
  const media=path.resolve(__dirname,'../Media');
  for(const [name,region] of Object.entries(regions)){
    const file=path.join(media,name+'.tga'),src=fs.readFileSync(file);
    fs.writeFileSync(path.join(media,name+'LiquidAtlas.tga'),build(src,region));
    if(hash(fs.readFileSync(file))!==region.hash)throw Error('Base modified');
    console.log(`${name}: ${frames} masked frames, ${fps} fps, 1024-square atlas; base unchanged`);
  }
}
module.exports={regions,frames,cell,pad,size,fps,hash,sample,mask,colour,build};
