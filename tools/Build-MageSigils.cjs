// Coldsnap uses approved alpha silhouettes. Combustion restores the original
// painted RGBA seal and extracted hollow flame, including transparent gaps.
const fs=require('node:fs'),path=require('node:path');
const {buildSize}=require('./Build-SkycutterSizes.cjs');
const cache=path.join(__dirname,'cache/mage-sigils'),media=path.join(__dirname,'../Media');
const count=32,cell=256,pad=4,columns=8,rows=4;
const source=JSON.parse(fs.readFileSync(path.join(cache,'source.json'),'utf8').replace(/^\uFEFF/,''));
const w=source.width,h=source.height,raw=fs.readFileSync(path.join(cache,'Coldsnap.bgra'));
const labels=new Int32Array(w*h),queue=new Int32Array(w*h),parts=[];
let id=0;
for(let start=0;start<w*h;start++){
 if(labels[start]||raw[start*4+3]<64)continue;
 id++;let head=0,tail=1;queue[0]=start;labels[start]=id;
 let x0=w,y0=h,x1=0,y1=0,total=0,sx=0,sy=0;
 while(head<tail){
  const p=queue[head++],x=p%w,y=Math.floor(p/w);
  x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);total++;sx+=x;sy+=y;
  for(const [dx,dy] of [[-1,0],[1,0],[0,-1],[0,1]]){
   const nx=x+dx,ny=y+dy,q=ny*w+nx;
   if(nx<0||nx>=w||ny<0||ny>=h||labels[q]||raw[q*4+3]<64)continue;
   labels[q]=id;queue[tail++]=q;
  }
 }
 parts.push({id,total,x0,y0,x1,y1,cx:sx/total,cy:sy/total});
}
const pupil=parts.find(p=>p.total>1000&&Math.abs(p.cx/w-.5)<.06&&Math.abs(p.cy/h-.385)<.06&&p.x1-p.x0<w*.3);
const curls=parts.filter(p=>p.total>1000&&(p.cx/w<.25||p.cx/w>.75)&&p.cy/h>.4&&p.cy/h<.75);
if(!pupil||curls.length!==2)throw Error('Expected one pupil and two large independent curls');
const selected=new Set(curls.map(p=>p.id)),blue=[255,194,36];
const masks={details:Buffer.alloc(raw.length),pupil:Buffer.alloc(raw.length),flow:Buffer.alloc(raw.length)};
for(let p=0;p<w*h;p++){
 let label=labels[p];
 // Retain contour antialiasing but discard the generator's near-invisible aura
 // that otherwise connects unrelated glyphs into one component.
 if(!label&&raw[p*4+3]){
  const x=p%w,y=Math.floor(p/w);
  outer:for(let r=1;r<=2;r++)for(let dy=-r;dy<=r;dy++)for(let dx=-r;dx<=r;dx++){
   const nx=x+dx,ny=y+dy;
   if(nx>=0&&nx<w&&ny>=0&&ny<h&&labels[ny*w+nx]){label=labels[ny*w+nx];break outer;}
  }
 }
 if(!label)continue;
 const group=label===pupil.id?'pupil':selected.has(label)?'flow':'details',b=masks[group];
 for(let k=0;k<3;k++)b[p*4+k]=blue[k];
 b[p*4+3]=raw[p*4+3];
}
function save(name,data){
 const color=name.startsWith('Cold')?blue:[35,190,255];
 // GDI's premultiplied rounding may vary RGB at stroke edges. Keep only its
 // coverage; these self-emissive vectors have exactly one RGB, including bleed.
 if(name.startsWith('Cold'))for(let p=18;p<data.length;p+=4)for(let k=0;k<3;k++)data[p+k]=color[k];
 // Original seal has a few alpha=1 background remnants. Clear that invisible
 // residue so its center and gaps are genuinely empty, not a tinted disc.
 if(name==='CombustionSeal')for(let p=21;p<data.length;p+=4)if(data[p]<=1)data[p]=0;
 fs.writeFileSync(path.join(media,name+'.tga'),data);
}
function tga(data,width,height){
 const header=Buffer.alloc(18);header[2]=2;header[16]=32;header[17]=40;header.writeUInt16LE(width,12);header.writeUInt16LE(height,14);
 return Buffer.concat([header,data]);
}
function atlas(frames,name){
 const width=columns*cell,height=rows*cell,out=Buffer.alloc(width*height*4);
 frames.forEach((frame,f)=>{
  for(let y=0;y<cell-pad*2;y++){
   // buildSize has a power-of-two backing, with 248 pixels of active content.
   frame.copy(out,(((Math.floor(f/columns)*cell+pad+y)*width)+(f%columns)*cell+pad)*4,18+y*cell*4,18+(y*cell+cell-pad*2)*4);
  }
 });
 save(name,tga(out,width,height));
}
function alphaAt(b,x,y){
 if(x<0||y<0||x>=w-1||y>=h-1)return 0;
 const ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy,p=(iy*w+ix)*4+3;
 return b[p]*(1-fx)*(1-fy)+b[p+4]*fx*(1-fy)+b[p+w*4]*(1-fx)*fy+b[p+w*4+4]*fx*fy;
}
// Normalize source to 512 once, preserving approved silhouettes. The frame
// transforms sample original source alpha directly, avoiding cumulative blur.
const eyeFrames=[],flowFrames=[];
for(let f=0;f<count;f++){
 const t=f/count*Math.PI*2,eye=Buffer.alloc(512*512*4),flow=Buffer.alloc(512*512*4);
 const px=30*Math.sin(t),py=17*Math.cos(t+.3);
 for(let y=0;y<512;y++)for(let x=0;x<512;x++){
  const sx=(x+.5)*w/512-.5,sy=(y+.5)*h/512-.5,p=(y*512+x)*4;
  for(let k=0;k<3;k++){eye[p+k]=blue[k];flow[p+k]=blue[k];}
  eye[p+3]=Math.round(alphaAt(masks.pupil,sx-px,sy-py));
  const v=Math.max(0,Math.min(1,(sy/h-.4)/.31)),envelope=Math.sin(v*Math.PI);
  const mirror=sx<w/2?1:-1;
  const dx=mirror*11*envelope*Math.sin(t-v*Math.PI*3);
  const dy=5*envelope*Math.sin(t-v*Math.PI*2+.6);
  flow[p+3]=Math.round(alphaAt(masks.flow,sx-dx,sy-dy));
 }
 eyeFrames.push(buildSize(eye,512,512,248,248));flowFrames.push(buildSize(flow,512,512,248,248));
}
save('ColdsnapDetails',buildSize(masks.details,w,h,512,512));
atlas(eyeFrames,'ColdsnapPupilAtlas');atlas(flowFrames,'ColdsnapFlowAtlas');
const combustion=JSON.parse(fs.readFileSync(path.join(cache,'combustion-source.json'),'utf8').replace(/^\uFEFF/,''));
save('CombustionSeal',buildSize(fs.readFileSync(path.join(cache,'seal.bgra')),combustion.seal.width,combustion.seal.height,512,512));
const flame=fs.readFileSync(path.join(cache,'flame.bgra')),sw=combustion.flame.width,sh=combustion.flame.height;
// Use one extracted hollow flame rather than crossfading independently drawn
// silhouettes. Sample original RGBA afresh for every frame; never accumulate blur.
// Clear negligible extraction residue, preserving antialiased luminous contours.
for(let p=3;p<flame.length;p+=4)if(flame[p]<=2)flame[p]=0;
function sampleFlame(x,y){
 if(x<0||x>=sw-1||y<0||y>=sh-1)return [0,0,0,0];
 const ix=Math.floor(x),iy=Math.floor(y),fx=x-ix,fy=y-iy,out=[0,0,0,0];
 for(let dy=0;dy<2;dy++)for(let dx=0;dx<2;dx++){
  const p=((iy+dy)*sw+ix+dx)*4,weight=(dx?fx:1-fx)*(dy?fy:1-fy),a=flame[p+3];
  out[3]+=weight*a;
  for(let k=0;k<3;k++)out[k]+=weight*flame[p+k]*a/255;
 }
 return out;
}
const flameFrames=[];
for(let f=0;f<count;f++){
 const frame=Buffer.alloc(512*512*4),phase=f/count*Math.PI*2;
 for(let y=0;y<512;y++)for(let x=0;x<512;x++){
  const u=(x+.5)/512,v=(y+.5)/512;
  const lift=Math.max(0,Math.min(1,(.72-v)/.48)),e=lift*lift*(3-2*lift);
  // Upper tongues gently ripple by at most ~1.5px at 512 resolution. Base stays
  // fixed. Periodic harmonics make the last-to-first step as small as any other.
  const dx=e*(.0022*Math.sin(phase+v*5)+.0007*Math.sin(2*phase-v*7+u*3));
  const dy=e*.0012*Math.sin(phase-v*6+u*4);
  const rgba=sampleFlame((u-dx)*sw-.5,(v-dy)*sh-.5),p=(y*512+x)*4;
  frame[p+3]=Math.round(rgba[3]);
  if(rgba[3]>0)for(let k=0;k<3;k++)frame[p+k]=Math.round(rgba[k]*255/rgba[3]);
 }
 flameFrames.push(buildSize(frame,512,512,248,248));
}
atlas(flameFrames,'CombustionFlameAtlas');
const manifest={source,combustion,count,cell,pad,columns,rows,pupil,curls,colors:{cold:blue,combustion:'original painted RGB'},
 files:['ColdsnapDetails','ColdsnapPupilAtlas','ColdsnapFlowAtlas','CombustionSeal','CombustionFlameAtlas'].map(n=>'Media/'+n+'.tga')};
fs.writeFileSync(path.join(cache,'manifest.json'),JSON.stringify(manifest,null,2));
console.log('Sigils: 5 RGBA textures, 32 frames per animated layer; pupil and two curls isolated.');
