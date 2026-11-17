const fs = require('node:fs');
const path = require('node:path');
const {buildSize} = require('./Build-SkycutterSizes.cjs');
const {sharpen} = require('./Build-SkycutterCAS.cjs');
const cache = path.join(__dirname, 'cache', 'rogue');
const media = path.join(__dirname, '..', 'Media');
const sizes = [192,288,384,576,768,1086];
function read(name) { return fs.readFileSync(path.join(cache,name+'.bgra')); }
function write(name,data) { fs.writeFileSync(path.join(media,name+'.tga'),data); }

for (const name of ['Gloomfang','Venomveil']) {
    write(name,buildSize(read(name),1086,724,768,512));
    const dagger=read(name+'Dagger');
    for (const width of sizes) {
        const height=width*2/3;
        write(name+'DaggerCASSize'+width,sharpen(buildSize(dagger,1086,724,width,height),width,height));
    }
}
