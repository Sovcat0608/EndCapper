// Extract verified sequence IDs/durations only; no model binaries are packaged.
const fs=require('fs'),path=require('path'),cp=require('child_process');
const root=path.resolve(__dirname,'../../EndCapper');
const files=cp.execFileSync('rg',['--files',root],{encoding:'utf8',maxBuffer:20e6}).split(/\r?\n/).filter(p=>/\d+\.m2$/i.test(p));
const models={};
for(const file of files){
 const raw=fs.readFileSync(file);let b=raw;
 if(raw.toString('ascii',0,4)==='MD21')b=raw.subarray(8,8+raw.readUInt32LE(4));
 if(b.length<36||b.toString('ascii',0,4)!=='MD20'||![272,273,274].includes(b.readUInt32LE(4)))continue;
 const n=b.readUInt32LE(28),o=b.readUInt32LE(32);if(n>10000||o+n*64>b.length)continue;
 const rows={};for(let i=0;i<n;i++){const p=o+i*64;if(b.readUInt16LE(p+2)!==0)continue;rows[b.readUInt16LE(p)]=b.readUInt32LE(p+4)/1000;}
 models[Number(path.basename(file,'.m2'))]=rows;
}
const text='local _,E=...\n-- Verified local M2 sequence headers; absent model = unknown, not unsupported.\nE.EffectAnimations={\n'+Object.entries(models).map(([id,rows])=>` [${id}]={${Object.entries(rows).map(([a,d])=>`[${a}]=${d}`).join(',')}},`).join('\n')+'\n}\n';
fs.writeFileSync(path.resolve(__dirname,'../EffectAnimations.lua'),text);
console.log('Verified animation metadata:',Object.keys(models).length,'models');
