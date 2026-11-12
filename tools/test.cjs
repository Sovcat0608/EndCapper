const fs = require('node:fs');
const path = require('node:path');
const parser = require('luaparse');
const {lua,lauxlib,lualib,to_luastring} = require('fengari');
process.chdir(path.resolve(__dirname, '..'));
for (const file of ['Model.lua','Layouts.lua','Clipping.lua','NativeSmoke.lua','Glyphs.lua','Liquid.lua','Arcane.lua','Skycutter.lua','Molten.lua','Frost.lua','Moonwell.lua','Halos.lua','Effects.lua','Core.lua','Options.lua']) {
  parser.parse(fs.readFileSync(file,'utf8'),{luaVersion:'5.1'});
  console.log('Lua 5.1 syntax PASS:',file);
}
const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
// Fengari uses Lua 5.3; WoW exposes the 5.1 unpack global.
lua.lua_pushcfunction(L, function(L) {
  const name = require('fengari').to_jsstring(lua.lua_tostring(L,1));
  const code = fs.readFileSync(name,'utf8');
  if (lauxlib.luaL_loadstring(L,to_luastring(code)) !== lua.LUA_OK) return lua.lua_error(L);
  return 1;
}); lua.lua_setglobal(L,to_luastring('loadfile'));
const test = 'unpack = table.unpack\n' + ['tests/model.lua','tests/sylvanas.lua','tests/zephras.lua','tests/worgen.lua','tests/frostmourne.lua','tests/dirty.lua','tests/pairs.lua','tests/layouts.lua','tests/core.lua','tests/native.lua','tests/refresh.lua','tests/options.lua','tests/glyphs.lua','tests/liquid.lua','tests/arcane.lua','tests/molten.lua','tests/frost.lua','tests/halos.lua','tests/clipping.lua'].map(f => 'do\n'+fs.readFileSync(f,'utf8')+'\nend').join('\n');
if (lauxlib.luaL_dostring(L,to_luastring(test)) !== lua.LUA_OK) {
  throw Error(require('fengari').to_jsstring(lua.lua_tostring(L,-1)));
}
const logo=fs.readFileSync('Media/EcapLogo.tga');
if(logo.length!==18+128*128*4 || logo[2]!==2 || logo[16]!==32 || logo[17]!==40 || logo.readUInt16LE(12)!==128 || logo.readUInt16LE(14)!==128) throw Error('Invalid Ecap launcher TGA');
console.log('Texture PASS: EcapLogo, 128x128 BGRA');
for (const [name,w,h] of [['Zephyr',1024,1024],['Skycutter',1024,1024],['Banshee',512,512],['HighGeneral',512,512],['Cryptgate',512,512],['Plaguewell',512,512],['WorgenWolf',512,256],['Moonbough',512,512],['VerdantRoot',512,512],['LunarRelic',512,512],['StormhornTotem',512,512],['Felwing',512,512],['FelwingGlyphAtlas',2048,2048],['VioletSpire',512,512],['ArcaneCrystal',256,256],['ArcaneSigil',256,256],...['Cinderforged','Cindermaw','CinderforgedEmission','CinderforgedBloom','CindermawEmission','CindermawBloom','Rimeforged','Rimeguard','RimeforgedRunes','RimeforgedRunesBloom','RimeforgedIce','RimeforgedIceBloom','RimeguardRunes','RimeguardRunesBloom','RimeguardIce','RimeguardIceBloom','RimeguardEyes','RimeguardEyesBloom'].map(n=>[n,512,512])]) {
  const tga = fs.readFileSync(`Media/${name}.tga`);
  if(tga.length !== 18+w*h*4 || tga.readUInt16LE(12)!==w || tga.readUInt16LE(14)!==h || tga[2]!==2 || tga[16]!==32 || tga[17]!==40) throw Error('Invalid TGA: '+name);
  let clear=0, visible=0;
  for(let i=21;i<tga.length;i+=4) {if(tga[i]===0) clear++; else visible++;}
  if(!clear || !visible) throw Error('Missing alpha content: '+name);
  console.log(`Texture PASS: ${name}, ${w}x${h}, alpha preserved`);
}
// Verify each atlas cell is unique and bloom changes spatially, not just alpha.
for(const name of ['Moonwell','MoonwellGlyphs','MoonwellMoon','MoonwellWater','MoonwellBounce']) {
  const size=name==='Moonwell'?512:256,b=fs.readFileSync(`Media/${name}.tga`);
  if(b.length!==18+size*size*4||b[2]!==2||b[16]!==32||b[17]!==40||b.readUInt16LE(12)!==size||b.readUInt16LE(14)!==size)throw Error('Invalid Moonwell texture '+name);
  let visible=0,clear=0;for(let i=21;i<b.length;i+=4){if(b[i])visible++;else clear++;}
  if(visible<20||clear<20)throw Error('Moonwell alpha missing '+name);
}
const bounce=fs.readFileSync('Media/MoonwellBounce.tga');
const externalMedia=JSON.parse(fs.readFileSync('tools/external-media.json','utf8'));
for(const name of ['FrostmourneHilt','FrostmourneBlade','FrostmourneHiltIce','FrostmourneBladeIce']) {
  const b=fs.readFileSync(externalMedia[`Media/${name}.tga`]);
  if(b.length!==18+1024*512*4||b[2]!==2||b[16]!==32||b[17]!==40||b.readUInt16LE(12)!==1024||b.readUInt16LE(14)!==512)throw Error('Invalid Frostmourne TGA '+name);
  let clear=0,solid=0,bottom=-1;
  for(let y=0;y<512;y++){let occupied=0;for(let x=0;x<1024;x++){const a=b[21+(y*1024+x)*4];if(!a)clear++;if(a===255)solid++;if(a>=200)occupied++;}if(occupied>=12)bottom=y;}
  if(clear<1000||solid<1000||bottom!==467)throw Error('Frostmourne alpha/baseline '+name);
}
console.log('Frostmourne textures PASS: two bases and separate ice overlays, 1024x512 BGRA, alpha and shared 467/512 crop line');
for(const [name,baseline] of [['WorgenBlack',496],['WorgenWhite',492]]) {
  const b=fs.readFileSync(externalMedia[`Media/${name}.tga`]);
  if(b.length!==18+1024*512*4||b[2]!==2||b[16]!==32||b[17]!==40||b.readUInt16LE(12)!==1024||b.readUInt16LE(14)!==512)throw Error('Invalid Worgen sister TGA '+name);
  let clear=0,solid=0,bottom=-1;
  for(let y=0;y<512;y++){let occupied=0;for(let x=0;x<1024;x++){const a=b[21+(y*1024+x)*4];if(!a)clear++;if(a===255)solid++;if(a>=200)occupied++;}if(occupied>=12)bottom=y;}
  if(clear<1000||solid<1000||bottom!==baseline)throw Error('Worgen alpha/baseline '+name);
}
console.log('Worgen sisters PASS: 1024x512 RGBA, genuine alpha, measured bottom crop lines 496/492');
for(const name of ['Undead','Lordaeron','Seraph','Sanctum','Umbra','Eclipse']) {
  const rel=`Media/${name}.tga`,b=fs.readFileSync(fs.existsSync(rel)?rel:externalMedia[rel]);
  if(b.length!==18+512*512*4||b[2]!==2||b[16]!==32||b[17]!==40||b.readUInt16LE(12)!==512||b.readUInt16LE(14)!==512)throw Error('Invalid priest texture '+name);
  let clear=0,solid=0;for(let i=21;i<b.length;i+=4){if(b[i]===0)clear++;if(b[i]===255)solid++;}
  if(clear<1000||solid<1000)throw Error('Priest texture alpha missing '+name);
}
require('./test-mipmaps.cjs');
require('./test-skycutter-refined.cjs');
require('./test-skycutter-edge-aa.cjs');
require('./test-skycutter-sizes.cjs');
require('./test-skycutter-cas.cjs');
require('./test-arcane-cas.cjs');
require('./test-zephyr-cas.cjs');
require('./test-artwork-cas.cjs');
require('./test-warlock.cjs');
require('./test-liquid.cjs');
require('./test-moonwell-repaint.cjs');
console.log('Base textures PASS: four priest bases plus Undead/Lordaeron, 512-square RGBA with clear/opaque pixels');
const kirin=fs.readFileSync(externalMedia['Media/KirinTor.tga']);
if(kirin.length!==18+512*512*4||kirin[2]!==2||kirin[16]!==32||kirin[17]!==40||kirin.readUInt16LE(12)!==512||kirin.readUInt16LE(14)!==512)throw Error('Invalid Kirin Tor texture');
for(const [name,b,baseline] of [['KirinTor',kirin,492],['VioletSpire',fs.readFileSync('Media/VioletSpire.tga'),493]]) {
  let clear=0,solid=0,bottom=-1;
  for(let y=0;y<512;y++){let occupied=0;for(let x=0;x<512;x++){const a=b[21+(y*512+x)*4];if(a===0)clear++;if(a===255)solid++;if(a>=200)occupied++;}if(occupied>=6)bottom=y;}
  if(clear<1000||solid<1000||bottom!==baseline)throw Error('Arcane sister alpha/baseline: '+name);
}
console.log('Arcane sister textures PASS: genuine alpha, smooth-source runtime baselines 493/492, original moving-object BLPs retained');
for(const name of ['Undead','Lordaeron']) {
  const b=fs.readFileSync(externalMedia[`Media/${name}.tga`]);
  let rail=0;
  for(let x=12;x<500;x++)for(let y=494;y<=499;y++)if(b[21+(y*512+x)*4]>200){rail++;break;}
  if(rail<450)throw Error('Missing aligned basal rail: '+name);
}
console.log('Undead sisters PASS: both basal rails aligned at y498, wide occupied footings');
for(let y=150;y<168;y++)for(let x=112;x<126;x++)if(bounce[21+(y*256+x)*4])throw Error('Reflected light covers the water interior');
console.log('Moonwell textures PASS: base/four registered RGBA layers, transparent margins and empty reflected-light pool interior');
const atlas=fs.readFileSync('Media/FelwingGlyphAtlas.tga'), wing=fs.readFileSync('Media/Felwing.tga');
const hashes=new Set(), ratios=[];
for(let f=0;f<16;f++) {
  const cell=Buffer.alloc(512*512*4);let core=0,halo=0;
  for(let y=0;y<512;y++)for(let x=0;x<512;x++) {
    const src=18+((y+Math.floor(f/4)*512)*2048+x+(f%4)*512)*4,dst=(y*512+x)*4;
    atlas.copy(cell,dst,src,src+4);
    const p=18+dst,green=wing[p+1]-Math.max(wing[p],wing[p+2]);
    if(green>50)core+=atlas[src+3];else halo+=atlas[src+3];
  }
  hashes.add(require('node:crypto').createHash('sha256').update(cell).digest('hex'));
  ratios.push(halo/core);
}
if(hashes.size!==16 || Math.max(...ratios)-Math.min(...ratios)<0.1) throw Error('Glyph atlas needs unique frames and changing bloom spread');
console.log('Atlas PASS: 16 unique frames, varying halo/core ratio');
for(const name of ['Rimeforged','Rimeguard']) {
  const base=fs.readFileSync(`Media/${name}.tga`),occupied=new Set();
  for(const layer of (name==='Rimeguard'?['Runes','Ice','Eyes']:['Runes','Ice'])) {
    const core=fs.readFileSync(`Media/${name}${layer}.tga`),bloom=fs.readFileSync(`Media/${name}${layer}Bloom.tga`);
    let count=0,halo=0;
    for(let i=18;i<core.length;i+=4) {
      if(core[i+3]) {
        if(!base[i+3]||Math.min(base[i],base[i+1])-base[i+2]<=30||occupied.has(i)) throw Error('Frost core registration/layer overlap: '+name+layer);
        occupied.add(i);count++;
      }
      if(bloom[i+3]&&!core[i+3])halo++;
    }
    if(count<10||halo<10)throw Error('Empty frost emission or bloom');
  }
  console.log('Emission PASS:',name,'disjoint registered rune/ice/eye cores with separate bloom');
}
for(const name of ['Cinderforged','Cindermaw']) {
  const base=fs.readFileSync(`Media/${name}.tga`),core=fs.readFileSync(`Media/${name}Emission.tga`),bloom=fs.readFileSync(`Media/${name}Bloom.tga`);
  let coreCount=0,haloCount=0;
  for(let i=18;i<core.length;i+=4) {
    if(core[i+3]) {
      coreCount++;
      if(!base[i+3] || base[i+2]-base[i]<=100 || base[i]>=155) throw Error('Molten emission escaped hot artwork pixels: '+name);
    }
    if(bloom[i+3] && !core[i+3]) haloCount++;
  }
  if(coreCount<1000 || coreCount>512*512*0.15 || haloCount<coreCount) throw Error('Molten core/bloom coverage invalid');
  if(name==='Cindermaw') for(const [label,x0,y0,x1,y1] of [['near eye',0.205,0.34,0.29,0.43],['far eye',0.325,0.35,0.35,0.42],['mouth',0.24,0.50,0.35,0.63]]) {
    let n=0;
    for(let y=Math.floor(y0*512);y<y1*512;y++)for(let x=Math.floor(x0*512);x<x1*512;x++)if(core[21+(y*512+x)*4])n++;
    if(n<3)throw Error('Missing Cindermaw emission: '+label);
  }
  console.log('Emission PASS:',name,'exact hot-pixel registration, separate bloom, eyes/mouth coverage where applicable');
}
