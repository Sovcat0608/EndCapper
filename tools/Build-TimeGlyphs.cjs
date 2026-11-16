// Extract the existing painted symbols; never repaint the approved base art.
const fs=require('node:fs'),path=require('node:path');
const {buildSize}=require('./Build-SkycutterSizes.cjs');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
const cache=path.join(__dirname,'cache/timeworks'),media=path.join(__dirname,'../Media');
const regions={
 Timekeeper:[[265,167,24,18,'warm'],[194,203,26,25,'carved'],[106,411,17,27,'warm'],[141,504,23,30,'warm'],[183,558,22,20,'warm']],
 Timelost:[[633,194,34,39],[771,181,29,34],[923,153,35,32],[584,496,36,35],[782,540,45,37,'ink']],
};
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t);};
function inside(x,y,p){let yes=false;for(let i=0,j=p.length-1;i<p.length;j=i++)if((p[i][1]>y)!==(p[j][1]>y)&&x<(p[j][0]-p[i][0])*(y-p[i][1])/(p[j][1]-p[i][1])+p[i][0])yes=!yes;return yes;}
function blur(input,w,h,sigma){
 const radius=Math.ceil(sigma*3),weights=[];let sum=0;
 for(let i=-radius;i<=radius;i++){const v=Math.exp(-i*i/(2*sigma*sigma));weights.push(v);sum+=v;}
 const tmp=new Float32Array(input.length),out=new Float32Array(input.length);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++)for(let d=-radius;d<=radius;d++)if(x+d>=0&&x+d<w)tmp[y*w+x]+=input[y*w+x+d]*weights[d+radius]/sum;
 for(let y=0;y<h;y++)for(let x=0;x<w;x++)for(let d=-radius;d<=radius;d++)if(y+d>=0&&y+d<h)out[y*w+x]+=tmp[(y+d)*w+x]*weights[d+radius]/sum;
 return out;
}
for(const [name,rois] of Object.entries(regions)){
 const records=JSON.parse(fs.readFileSync(path.join(cache,'sources.json'),'utf8').replace(/^\uFEFF/,''));
 const {width:w,height:h}=records.find(x=>x.name===name),source=fs.readFileSync(path.join(cache,name+'.bgra'));
 const mask=new Float32Array(w*h),core=Buffer.alloc(source.length),bloom=Buffer.alloc(source.length);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const p=(y*w+x)*4,b=source[p],g=source[p+1],r=source[p+2],a=source[p+3]/255;
  let value=0;
  for(const [cx,cy,rx,ry,type] of rois){
   const radius=((x-cx)/rx)**2+((y-cy)/ry)**2;if(radius>=1)continue;
   const coverage=1-smooth(.78,1,radius);
   let select;
   if(type==='ink')select=smooth(.27,.38,1-g/Math.max(1,r))*smooth(110,170,r)*smooth(25,55,g-b);
   else if(type==='warm')select=smooth(140,220,r)*smooth(65,135,g)*smooth(55,110,r-b);
   else if(type==='carved')select=inside(x,y,[[173,222],[179,206],[176,199],[186,190],[202,181],[211,184],[207,198],[214,205],[207,215],[194,221],[190,214],[182,224]])?(1-smooth(85,150,g))*smooth(65,125,r):0;
   else select=smooth(205,248,r)*smooth(100,160,g)*smooth(65,125,r-b);
   value=Math.max(value,select*coverage*a);
  }
  mask[y*w+x]=value;
  if(value>0){core[p]=55;core[p+1]=181;core[p+2]=255;core[p+3]=Math.round(value*255);}
 }
 const halo=blur(mask,w,h,6);
 for(let p=0;p<source.length;p+=4){
  bloom[p]=28;bloom[p+1]=139;bloom[p+2]=255;
  bloom[p+3]=Math.round(Math.min(1,halo[p/4]*2.5)*source[p+3]);
 }
 for(const [suffix,pixels,n] of [['Emission',core,512],['Bloom',bloom,256]]){
  const output=sharpen(buildSize(pixels,w,h,n,n),n,n);
  fs.writeFileSync(path.join(media,name+'Glyph'+suffix+'CAS.tga'),output);
 }
 fs.writeFileSync(path.join(cache,name+'GlyphMask.bgra'),core);
 console.log(name+': source glyph mask and registered core/bloom baked');
}
