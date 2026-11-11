// Derive registered green emission from the approved painted pixels.
const fs = require('node:fs');
const path = require('node:path');
const {buildBLP} = require('./Build-HaloMipmaps.cjs');
const media = path.resolve(__dirname, '../Media');
const clamp = value => Math.max(0, Math.min(1, value));

function blur(input, size, radiusX, radiusY) {
  const horizontal = new Float32Array(input.length);
  const output = new Float32Array(input.length);
  for (let y = 0; y < size; y++) {
    let sum = 0;
    for (let x = 0; x <= radiusX; x++) sum += input[y * size + x];
    for (let x = 0; x < size; x++) {
      horizontal[y * size + x] = sum / (radiusX * 2 + 1);
      if (x >= radiusX) sum -= input[y * size + x - radiusX];
      if (x + radiusX + 1 < size) sum += input[y * size + x + radiusX + 1];
    }
  }
  for (let x = 0; x < size; x++) {
    let sum = 0;
    for (let y = 0; y <= radiusY; y++) sum += horizontal[y * size + x];
    for (let y = 0; y < size; y++) {
      output[y * size + x] = sum / (radiusY * 2 + 1);
      if (y >= radiusY) sum -= horizontal[(y - radiusY) * size + x];
      if (y + radiusY + 1 < size) sum += horizontal[(y + radiusY + 1) * size + x];
    }
  }
  return output;
}

for (const name of ['Hexbound', 'Soulbound', 'SoulboundCrystal']) {
  const source = fs.readFileSync(path.join(media, name + '.tga'));
  const size = source.readUInt16LE(12);
  if (source[2] !== 2 || source[16] !== 32 || source[17] !== 40 ||
      source.readUInt16LE(14) !== size || source.length !== 18 + size * size * 4) {
    throw Error('Expected square BGRA source for ' + name);
  }
  const mask = new Float32Array(size * size);
  for (let i = 0; i < mask.length; i++) {
    const p = 18 + i * 4;
    const blue = source[p], green = source[p + 1], red = source[p + 2];
    // Green dominance excludes gold, cloth and neutral specular highlights.
    mask[i] = clamp((green - red - 12) / 55) * clamp((green - blue - 25) / 85) *
      clamp((green - 50) / 100) * source[p + 3] / 255;
  }
  let halo = mask;
  for (let pass = 0; pass < 3; pass++) halo = blur(halo, size, 3, 5);
  const emission = Buffer.alloc(mask.length * 4);
  const bloom = Buffer.alloc(emission.length);
  for (let i = 0; i < mask.length; i++) {
    const p = i * 4;
    emission[p] = 8; emission[p + 1] = 255; emission[p + 2] = 135;
    emission[p + 3] = Math.round(mask[i] * 235);
    bloom[p] = 12; bloom[p + 1] = 255; bloom[p + 2] = 105;
    bloom[p + 3] = Math.round(clamp(halo[i] * 2.4) * 200);
  }
  if (name === 'SoulboundCrystal') {
    fs.writeFileSync(path.join(media, name + '.blp'), buildBLP(source.subarray(18), size, size));
    // One pulse layer keeps the moving core and soft bloom on the same timeline.
    for (let i = 0; i < mask.length; i++) {
      emission[i * 4 + 3] = Math.max(emission[i * 4 + 3], bloom[i * 4 + 3]);
    }
    fs.writeFileSync(path.join(media, name + 'Emission.blp'), buildBLP(emission, size, size));
  } else {
    for (const [suffix, pixels] of [['Emission', emission], ['Bloom', bloom]]) {
      fs.writeFileSync(path.join(media, name + suffix + '.tga'), Buffer.concat([source.subarray(0, 18), pixels]));
    }
  }
  console.log(name + ': registered green core and bloom, ' + size + ' square');
}
