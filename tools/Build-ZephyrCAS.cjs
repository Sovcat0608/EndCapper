// Apply the accepted maximum CAS parameter to the original static artwork.
const fs=require('node:fs'),path=require('node:path');
const {sharpen,sharpness,blend}=require('./Build-SkycutterCAS.cjs');
const media=path.join(__dirname,'../Media');
const original=fs.readFileSync(path.join(media,'Zephyr.tga'));
if(original.readUInt16LE(12)!==1024||original.readUInt16LE(14)!==1024)
  throw Error('Expected original 1024-square Zephyr');
fs.writeFileSync(path.join(media,'ZephyrCAS.tga'),sharpen(original,1024,1024));
console.log(`Zephyr CAS: sharpness ${sharpness}, blend ${blend}, original dimensions and alpha retained`);
