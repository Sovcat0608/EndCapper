// Approved split source, reconstructed recess, and three painted complete gears.
// Static layers stay unsharpened. Moving layers reuse the accepted CAS recipe.
const fs=require('node:fs'),path=require('node:path');
const {buildSize}=require('./Build-SkycutterSizes.cjs');
const {sharpen}=require('./Build-SkycutterCAS.cjs');
const cache=path.join(__dirname,'cache/timeworks'),media=path.join(__dirname,'../Media');
const records=JSON.parse(fs.readFileSync(path.join(cache,'sources.json'),'utf8').replace(/^\uFEFF/,''));
const source=name=>{const r=records.find(r=>r.name===name);return {...r,pixels:fs.readFileSync(path.join(cache,name+'.bgra'))};};
const sizes=[64,96,128,192,256];
const gears=[{x:866,y:298,diameter:144,period:32,direction:1},{x:818,y:413,diameter:114,period:24,direction:-1},{x:914,y:440,diameter:128,period:28,direction:1}];
const windows=[[[818,234],[876,230],[918,253],[938,289],[937,326],[927,339],[859,338],[852,291],[836,260]],
 [[847,374],[942,374],[951,402],[931,417],[907,424],[876,448],[850,472],[824,484],[795,491],[755,493],[789,471],[817,439],[836,405]]];
function inside(x,y,p){let yes=false;for(let i=0,j=p.length-1;i<p.length;j=i++)if((p[i][1]>y)!==(p[j][1]>y)&&x<(p[j][0]-p[i][0])*(y-p[i][1])/(p[j][1]-p[i][1])+p[i][0])yes=!yes;return yes;}
function tga(p,w,h){const head=Buffer.alloc(18);head[2]=2;head[16]=32;head[17]=40;head.writeUInt16LE(w,12);head.writeUInt16LE(h,14);return Buffer.concat([head,p]);}
function save(name,b){fs.writeFileSync(path.join(media,name+'.tga'),b);}
function snapshot(name,p,w,h){fs.writeFileSync(path.join(cache,name+'.tga'),tga(p,w,h));}
function sample(s,x,y){const px=Math.max(0,Math.min(s.width-1,Math.round(x))),py=Math.max(0,Math.min(s.height-1,Math.round(y)));return (py*s.width+px)*4;}
function build(){
 const keeper=source('Timekeeper'),lost=source('Timelost'),recess=source('Recess'),sheet=source('Gears');
 const w=lost.width,h=lost.height,back=Buffer.from(lost.pixels),front=Buffer.alloc(back.length),coverage=Buffer.alloc(w*h);
 // The foreground is the original clock face/ribbon around the recess. Its
 // windows are fixed in artwork space so rotating wheels cannot cross the rim.
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const p=(y*w+x)*4;let count=0;
  for(const dx of [.25,.75])for(const dy of [.25,.75])if(windows.some(poly=>inside(x+dx,y+dy,poly)))count++;
  const hole=count/4;coverage[y*w+x]=Math.round(hole*255);
  const region=x>=735&&x<=1000&&y>=210&&y<=540;
  if(region){
   // Reconstruct all pixels beneath the moving circles, including the parts
   // hidden by the unchanged front ring and ribbon. The source edit supplies
   // a quiet cavity; use its upper open recess as a continuous material patch.
   const q=sample(recess,(863+(x-863)*.25)/w*recess.width,(283+(y-283)*.12)/h*recess.height);
   for(let c=0;c<3;c++)back[p+c]=Math.round(recess.pixels[q+c]*.35);back[p+3]=lost.pixels[p+3];
   for(let c=0;c<3;c++)front[p+c]=lost.pixels[p+c];
   front[p+3]=Math.round(lost.pixels[p+3]*(1-hole));
  }
 }
 snapshot('TimelostBackdrop',back,w,h);snapshot('TimelostFront',front,w,h);
 save('Timekeeper',buildSize(keeper.pixels,keeper.width,keeper.height,512,512));
 save('Timelost',buildSize(back,w,h,512,512));save('TimelostFront',buildSize(front,w,h,512,512));
 // Three independent, complete centred sprites. Crop each painted gear from
 // the common sheet, preserving a transparent rotation margin.
 for(let i=0;i<3;i++){
  const cell=sheet.width/3;let x0=cell,y0=sheet.height,x1=0,y1=0;
  for(let y=0;y<sheet.height;y++)for(let x=0;x<cell;x++)if(sheet.pixels[(y*sheet.width+i*cell+x)*4+3]>16){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}
  const n=Math.max(x1-x0+1,y1-y0+1)+16,cx=(x0+x1)/2,cy=(y0+y1)/2,pixels=Buffer.alloc(n*n*4);
  for(let y=0;y<n;y++)for(let x=0;x<n;x++){const sx=Math.round(cx+x-(n-1)/2),sy=Math.round(cy+y-(n-1)/2);if(sx>=0&&sx<cell&&sy>=0&&sy<sheet.height){const q=(sy*sheet.width+i*cell+sx)*4;sheet.pixels.copy(pixels,(y*n+x)*4,q,q+4);}}
  snapshot('TimelostGear'+(i+1),pixels,n,n);
  for(const size of sizes)save('TimelostGear'+(i+1)+'CASSize'+size,sharpen(buildSize(pixels,n,n,size,size),size,size));
 }
 // Frame animation is restricted to chromatic sand, never the glass/metal.
 // Authored sand remains as a static fallback. Travelling grains and descending
 // highlights crossfade through 32 frames; reservoir volume stays constant.
 const region={x:300,y:380,w:184,h:208},cell=128,pad=3,cols=8,frames=32,atlasW=1024,atlasH=512;
 const atlas=Buffer.alloc(atlasW*atlasH*4),mask=Buffer.alloc((cell-pad*2)**2);
 for(let f=0;f<frames;f++)for(let y=pad;y<cell-pad;y++)for(let x=pad;x<cell-pad;x++){
  const sx=region.x+(x-pad+.5)/(cell-pad*2)*region.w,sy=region.y+(y-pad+.5)/(cell-pad*2)*region.h;
  const q=sample(keeper,sx,sy),b=keeper.pixels[q],g=keeper.pixels[q+1],r=keeper.pixels[q+2],a=keeper.pixels[q+3];
  const chroma=Math.max(0,Math.min(1,(r-b-65)/90))*Math.max(0,Math.min(1,(g-75)/95));
  const edge=Math.min(1,(sx-region.x)/7,(region.x+region.w-sx)/7,(sy-region.y)/5,(region.y+region.h-sy)/5);
  const upper=inside(sx,sy,[[316,382],[345,393],[389,397],[435,390],[464,380],[445,411],[414,437],[394,460],[385,460],[365,435],[337,414]]);
  const lower=inside(sx,sy,[[306,564],[342,552],[368,539],[387,522],[397,522],[410,538],[440,551],[474,562],[467,579],[315,579]]);
  const stream=sx>386&&sx<397&&sy>450&&sy<540;
  const select=(upper||lower||stream?1:0)*chroma*Math.max(0,edge)*a/255;
  const fall=(1+Math.sin(sy*.31+Math.sin(sx*.19)*.9-f/frames*Math.PI*2))*.5;
  const grain=(1+Math.sin(sx*1.31+sy*.79-f/frames*Math.PI*8))*.5;
  // Broader moving highlights and stronger amber troughs read at cap size.
  // Keep the sand mask and flow timing unchanged.
  const shine=Math.pow(fall,2.5)*(.45+.55*Math.pow(grain,3));
  const p=((Math.floor(f/cols)*cell+y)*atlasW+(f%cols)*cell+x)*4;
  atlas[p]=Math.min(255,b*.65+shine*100);atlas[p+1]=Math.min(255,g*.72+shine*170);atlas[p+2]=Math.min(255,r*.8+shine*140);atlas[p+3]=Math.round(select*230);
  mask[(y-pad)*(cell-pad*2)+x-pad]=Math.round(select*255);
 }
 save('TimekeeperSandAtlasCAS',sharpen(tga(atlas,atlasW,atlasH),atlasW,atlasH));
 fs.writeFileSync(path.join(cache,'sand-mask.bin'),mask);
 const manifest={sources:records,width:w,height:h,gears,sizes,sand:{...region,cell,pad,cols,frames,atlasW,atlasH,cycle:2},baselines:{timekeeper:700/724,timelost:700/724}};
 fs.writeFileSync(path.join(cache,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 console.log('Timeworks: 3 static layers, 15 CAS gear textures, 32-frame sand atlas');
}
if(require.main===module)build();
module.exports={gears,sizes,windows};
